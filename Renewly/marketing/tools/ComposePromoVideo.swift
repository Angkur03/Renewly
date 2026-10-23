//
// ComposePromoVideo.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//
// Turns recordings of the in-app demo tour (capture-promo-video.sh) into two videos per language:
//   app-preview-iphone.mp4  886×1920 App Store app preview: app footage with captions
//   promo-vertical.mp4      1080×1920 brand video for Reels, TikTok and Shorts
//
// Build:
//   swiftc -parse-as-library -O -D PROMO_VIDEO ComposePromoVideo.swift ComposeScreenshots.swift \
//     ScreenshotCopy.swift PromoVideoCopy.swift -o /tmp/compose-promo-video
// Run:
//   /tmp/compose-promo-video <recordings-dir> <output-dir> <AppIcon.png> [run-id ...]
//

import AppKit
import AVFoundation
import CoreImage

enum VideoError: Error, CustomStringConvertible {
    case usage
    case missingVideoTrack(String)
    case readFailed(String)
    case writeFailed(String)
    case tourNotFound(String, onsets: [Double])

    var description: String {
        switch self {
        case .usage: "Usage: compose-promo-video <recordings-dir> <output-dir> <AppIcon.png> [run-id ...]"
        case .missingVideoTrack(let path): "No video track in \(path)"
        case .readFailed(let reason): "Could not read the recording: \(reason)"
        case .writeFailed(let reason): "Could not write the video: \(reason)"
        case .tourNotFound(let path, let onsets):
            "Could not find the demo tour in \(path). Was it recorded with -demo_tour YES? Screen changes at: "
                + onsets.map { String(format: "%.2f", $0) }.joined(separator: ", ")
        }
    }
}

/// The in-app tour's timeline in seconds. Mirrors `DemoTour.stops` in the app.
enum Tour {
    static let duration = 24.0
    /// The app's splash screen is still fading out when the tour starts, so footage begins a little later.
    static let footageStart = 1.0
    /// When each captioned scene starts, and which screenshot caption it shows.
    static let scenes: [(start: Double, captionIndex: Int)] = [(0, 0), (3, 1), (7.5, 4), (11.5, 3), (16, 5), (20, 2)]
    /// Moments the whole screen changes (pushes, pops, sheets), used to line a recording up with the timeline.
    static let transitions: [Double] = [3, 6.5, 7.5, 10.5, 11.5, 15, 16, 19, 20]

    /// The caption showing at `time` and how visible it is: it fades in as its scene starts and out before the next.
    static func caption(at time: Double, fadesOutAtEnd: Bool) -> (captionIndex: Int, alpha: Double) {
        let index = scenes.lastIndex { $0.start <= time } ?? 0
        let isLast = index == scenes.count - 1
        let end = isLast ? duration : scenes[index + 1].start
        let fade = 0.35
        let fadeIn = Easing.out((time - max(scenes[index].start, footageStart)) / fade)
        let fadeOut = isLast && !fadesOutAtEnd ? 1 : Easing.out((end - time) / fade)
        return (scenes[index].captionIndex, min(fadeIn, fadeOut))
    }
}

enum Easing {
    static func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
    static func out(_ value: Double) -> Double { 1 - pow(1 - clamp(value), 3) }
    static func inOut(_ value: Double) -> Double {
        let t = clamp(value)
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}

@main
struct ComposePromoVideo {
    static let fps = 30

    static func main() async {
        do {
            try await run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
    }

    static func run(arguments: [String]) async throws {
        guard arguments.count >= 3 else { throw VideoError.usage }
        let recordings = URL(fileURLWithPath: arguments[0])
        let outputRoot = URL(fileURLWithPath: arguments[1])
        let icon = try ComposeScreenshots.loadImage(URL(fileURLWithPath: arguments[2]))
        let selected = Set(arguments.dropFirst(3))

        for (locale, list) in captions.sorted(by: { $0.key < $1.key }) where selected.isEmpty || selected.contains(locale) {
            let recording = recordings.appending(path: "\(locale).mov")
            guard FileManager.default.fileExists(atPath: recording.path) else { continue }
            let tourStart = try await findTourStart(in: recording)
            print("\(locale): tour starts \(String(format: "%.2f", tourStart))s into the recording")

            let folder = outputRoot.appending(path: locale)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let layouts: [any VideoLayout] = [
                AppPreviewLayout(captions: list),
                SocialLayout(captions: list, outro: promoVideoOutro[locale] ?? "App Store", icon: icon),
            ]
            for layout in layouts {
                let output = folder.appending(path: layout.fileName)
                try await render(recording, tourStart: tourStart, layout: layout, to: output)
                print("  \(output.lastPathComponent)")
            }
        }
    }

    // MARK: Finding the tour

    /// Finds when the tour starts by matching big on-screen changes against `Tour.transitions`.
    static func findTourStart(in recording: URL) async throws -> Double {
        let reader = try await FrameReader.open(recording)
        var onsets: [Double] = []
        var previous: [Float] = []
        var lastChange = -Double.infinity
        while let frame = reader.nextFrame() {
            let thumbnail = reader.thumbnail(of: frame.buffer)
            if previous.count == thumbnail.count {
                let difference = zip(thumbnail, previous).reduce(Float(0)) { $0 + abs($1.0 - $1.1) } / Float(thumbnail.count)
                if difference > 1.5 {
                    if frame.time - lastChange > 0.3 {
                        onsets.append(frame.time)
                    }
                    lastChange = frame.time
                }
            }
            previous = thumbnail
        }

        var best: (start: Double, matched: Int, error: Double)?
        for onset in onsets {
            for transition in Tour.transitions where onset - transition >= 0 {
                let start = onset - transition
                guard start + Tour.duration <= reader.duration else { continue }
                var matched = 0
                var error = 0.0
                for expected in Tour.transitions {
                    let nearest = onsets.map { abs($0 - (start + expected)) }.min() ?? .infinity
                    if nearest < 0.3 {
                        matched += 1
                        error += nearest
                    }
                }
                if let current = best, matched < current.matched || (matched == current.matched && error >= current.error) {
                    continue
                }
                best = (start, matched, error)
            }
        }
        guard let best, best.matched > Tour.transitions.count / 2 else {
            throw VideoError.tourNotFound(recording.path, onsets: onsets)
        }
        return best.start
    }

    // MARK: Rendering

    static func render(_ recording: URL, tourStart: Double, layout: any VideoLayout, to output: URL) async throws {
        let silentVideo = FileManager.default.temporaryDirectory.appending(path: "renewly-\(UUID().uuidString).mov")
        defer { removeIfPresent(silentVideo) }

        let writer = try AVAssetWriter(outputURL: silentVideo, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: layout.width,
            AVVideoHeightKey: layout.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: layout.bitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps,
            ],
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: layout.width,
            kCVPixelBufferHeightKey as String: layout.height,
        ])
        writer.add(input)
        guard writer.startWriting() else { throw VideoError.writeFailed(writer.error?.localizedDescription ?? "unknown") }
        writer.startSession(atSourceTime: .zero)

        let reader = try await FrameReader.open(recording)
        let frameCount = Int((layout.duration * Double(fps)).rounded())
        for index in 0..<frameCount {
            let time = Double(index) / Double(fps)
            let footage = layout.tourTime(at: time).flatMap { reader.image(at: tourStart + $0) }
            guard let pool = adaptor.pixelBufferPool else { throw VideoError.writeFailed("no pixel buffer pool") }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let pixelBuffer else { throw VideoError.writeFailed("no pixel buffer") }
            try draw(into: pixelBuffer) { layout.draw(footage: footage, at: time) }

            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(5))
            }
            guard adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps))) else {
                throw VideoError.writeFailed(writer.error?.localizedDescription ?? "append failed")
            }
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw VideoError.writeFailed(writer.error?.localizedDescription ?? "unknown") }

        try await addSilentAudio(to: silentVideo, duration: layout.duration, output: output)
    }

    static func draw(into buffer: CVPixelBuffer, _ body: () -> Void) throws {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: base, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer),
                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
              ) else {
            throw VideoError.writeFailed("could not draw into a frame")
        }
        NSGraphicsContext.saveGraphicsState()
        let graphics = NSGraphicsContext(cgContext: context, flipped: false)
        graphics.imageInterpolation = .high
        NSGraphicsContext.current = graphics
        body()
        NSGraphicsContext.restoreGraphicsState()
    }

    /// App Store app previews need an audio track, so the video gets a silent one.
    /// Add music in the editing app of each social platform, where tracks are licensed.
    static func addSilentAudio(to video: URL, duration: Double, output: URL) async throws {
        let audioURL = FileManager.default.temporaryDirectory.appending(path: "renewly-silence-\(UUID().uuidString).m4a")
        defer { removeIfPresent(audioURL) }
        try writeSilence(to: audioURL, duration: duration)

        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: video)
        let audioAsset = AVURLAsset(url: audioURL)
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
              let videoOut = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioOut = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoError.writeFailed("could not combine video and audio")
        }
        let videoRange = CMTimeRange(start: .zero, duration: try await videoAsset.load(.duration))
        let audioDuration = try await audioAsset.load(.duration)
        try videoOut.insertTimeRange(videoRange, of: videoTrack, at: .zero)
        try audioOut.insertTimeRange(CMTimeRange(start: .zero, duration: CMTimeMinimum(audioDuration, videoRange.duration)), of: audioTrack, at: .zero)

        removeIfPresent(output)
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw VideoError.writeFailed("export unavailable")
        }
        try await export.export(to: output, as: .mp4)
    }

    static func writeSilence(to url: URL, duration: Double) throws {
        let sampleRate = 44_100.0
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 256_000,
        ])
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames),
              let channels = buffer.floatChannelData else {
            throw VideoError.writeFailed("could not create the audio buffer")
        }
        buffer.frameLength = frames
        for channel in 0..<Int(file.processingFormat.channelCount) {
            channels[channel].update(repeating: 0, count: Int(frames))
        }
        try file.write(from: buffer)
    }

    static func removeIfPresent(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            FileHandle.standardError.write(Data("Could not remove \(url.path): \(error)\n".utf8))
        }
    }
}

// MARK: Reading the recording

/// Reads a recording front to back. Simulator recordings have a variable frame rate, so frames are looked up by time.
final class FrameReader {
    /// Length of the recording. The last frame can be much earlier, because a still screen produces no frames.
    let duration: Double
    private let reader: AVAssetReader
    private let output: AVAssetReaderTrackOutput
    private let context = CIContext(options: [.cacheIntermediates: false])
    private var upcoming: CMSampleBuffer?
    private var current: CMSampleBuffer?
    private var currentImage: NSBitmapImageRep?

    static func open(_ url: URL) async throws -> FrameReader {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoError.missingVideoTrack(url.path)
        }
        return try FrameReader(asset: asset, track: track, duration: try await asset.load(.duration).seconds)
    }

    private init(asset: AVAsset, track: AVAssetTrack, duration: Double) throws {
        self.duration = duration
        reader = try AVAssetReader(asset: asset)
        output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ])
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else {
            throw VideoError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }
        upcoming = output.copyNextSampleBuffer()
    }

    /// The next frame in order, for scanning the whole recording.
    func nextFrame() -> (time: Double, buffer: CVPixelBuffer)? {
        while let sample = upcoming {
            upcoming = output.copyNextSampleBuffer()
            if let buffer = sample.imageBuffer {
                return (sample.presentationTimeStamp.seconds, buffer)
            }
        }
        return nil
    }

    /// The frame on screen at `time`. Times must not go backwards between calls.
    func image(at time: Double) -> NSBitmapImageRep? {
        var advanced = false
        while let sample = upcoming, sample.presentationTimeStamp.seconds <= time {
            current = sample
            upcoming = output.copyNextSampleBuffer()
            advanced = true
        }
        if advanced || currentImage == nil, let buffer = current?.imageBuffer {
            currentImage = makeImage(buffer)
        }
        return currentImage
    }

    func thumbnail(of buffer: CVPixelBuffer) -> [Float] {
        let width = 24
        let height = 52
        let image = CIImage(cvPixelBuffer: buffer)
        let scaled = image.transformed(by: CGAffineTransform(
            scaleX: CGFloat(width) / image.extent.width, y: CGFloat(height) / image.extent.height
        ))
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        context.render(
            scaled, toBitmap: &pixels, rowBytes: width * 4,
            bounds: CGRect(x: 0, y: 0, width: width, height: height), format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )
        return stride(from: 0, to: pixels.count, by: 4).map {
            Float(pixels[$0]) * 0.3 + Float(pixels[$0 + 1]) * 0.59 + Float(pixels[$0 + 2]) * 0.11
        }
    }

    private func makeImage(_ buffer: CVPixelBuffer) -> NSBitmapImageRep? {
        let image = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        return rep
    }
}

// MARK: Layouts

protocol VideoLayout {
    var fileName: String { get }
    var width: Int { get }
    var height: Int { get }
    var duration: Double { get }
    var bitRate: Int { get }
    /// Which moment of the tour to show at this video time, or nil when no app footage is on screen.
    func tourTime(at time: Double) -> Double?
    func draw(footage: NSBitmapImageRep?, at time: Double)
}

/// Draws `body` with the given opacity, skipping it when invisible.
func withAlpha(_ alpha: Double, _ body: () -> Void) {
    guard alpha > 0.001, let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setAlpha(alpha)
    body()
    context.restoreGState()
}

/// Full-screen app footage with a caption band, which App Store app previews allow.
struct AppPreviewLayout: VideoLayout {
    let captions: [Caption]
    let fileName = "app-preview-iphone.mp4"
    let width = 886
    let height = 1920
    let duration = Tour.duration - Tour.footageStart
    let bitRate = 10_000_000

    func tourTime(at time: Double) -> Double? { time + Tour.footageStart }

    func draw(footage: NSBitmapImageRep?, at time: Double) {
        let tour = time + Tour.footageStart
        let canvasWidth = CGFloat(width)
        let canvasHeight = CGFloat(height)
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight).fill()
        if let footage {
            let scale = max(canvasWidth / CGFloat(footage.pixelsWide), canvasHeight / CGFloat(footage.pixelsHigh))
            let size = NSSize(width: CGFloat(footage.pixelsWide) * scale, height: CGFloat(footage.pixelsHigh) * scale)
            footage.draw(in: NSRect(x: (canvasWidth - size.width) / 2, y: (canvasHeight - size.height) / 2, width: size.width, height: size.height))
        }

        let caption = Tour.caption(at: tour, fadesOutAtEnd: false)
        withAlpha(caption.alpha) {
            let band = canvasHeight * 0.25
            NSGradient(
                colors: [Palette.indigo.withAlphaComponent(0.96), Palette.violet.withAlphaComponent(0.8), Palette.violet.withAlphaComponent(0)],
                atLocations: [0, 0.6, 1], colorSpace: .sRGB
            )?.draw(in: NSRect(x: 0, y: 0, width: canvasWidth, height: band), angle: 90)

            let size = canvasWidth * 0.08
            let lift = (1 - caption.alpha) * 30
            ComposeScreenshots.drawText(
                ComposeScreenshots.styled(captions[caption.captionIndex].headline, size: size, weight: .heavy, color: .white),
                top: canvasHeight - band * 0.66 + lift, width: canvasWidth, height: canvasHeight,
                margin: canvasWidth * 0.08, maxHeight: size * 2.5
            )
        }
    }
}

/// Branded vertical video: intro, the tour inside a device frame with headlines, closing card.
struct SocialLayout: VideoLayout {
    static let introLength = 2.2
    static let outroLength = 3.0
    static let deviceEntrance = 0.8

    let captions: [Caption]
    let outro: String
    let icon: NSBitmapImageRep
    let fileName = "promo-vertical.mp4"
    let width = 1080
    let height = 1920
    let bitRate = 8_000_000

    var duration: Double { Self.introLength + Tour.duration - Tour.footageStart + Self.outroLength }

    /// Tour time for a video time. The tour section starts at `Tour.footageStart` once the intro ends.
    private func tour(at time: Double) -> Double {
        time - Self.introLength + Tour.footageStart
    }

    func tourTime(at time: Double) -> Double? {
        let tour = tour(at: time)
        guard tour >= Tour.footageStart - Self.deviceEntrance else { return nil }
        return min(max(tour, Tour.footageStart), Tour.duration)
    }

    func draw(footage: NSBitmapImageRep?, at time: Double) {
        let canvasWidth = CGFloat(width)
        let canvasHeight = CGFloat(height)
        ComposeScreenshots.drawBackground(width: canvasWidth, height: canvasHeight)
        let tour = tour(at: time)
        drawIntro(at: time, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        if let footage {
            drawDevice(footage, tour: tour, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        }
        drawHeadline(tour: tour, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        drawOutro(at: tour - Tour.duration, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
    }

    private func drawIntro(at time: Double, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        guard time < Self.introLength else { return }
        let exitStart = Self.introLength - Self.deviceEntrance
        let rise = CGFloat(Easing.inOut((time - exitStart) / Self.deviceEntrance)) * 160
        let exit = Easing.out((time - exitStart) / 0.35)
        let appear = Easing.out(time / 0.7)

        withAlpha(appear * (1 - exit)) {
            let iconSize = canvasWidth * 0.3 * CGFloat(0.75 + 0.25 * appear)
            let centerY = canvasHeight * 0.6 + rise
            ComposeScreenshots.drawIcon(
                icon, in: NSRect(x: (canvasWidth - iconSize) / 2, y: centerY - iconSize / 2, width: iconSize, height: iconSize),
                canvasWidth: canvasWidth
            )
        }
        let textTop = canvasHeight * 0.4 + canvasWidth * 0.2 - rise
        withAlpha(Easing.out((time - 0.25) / 0.6) * (1 - exit)) {
            ComposeScreenshots.drawText(
                ComposeScreenshots.styled("Renewly", size: canvasWidth * 0.11, weight: .heavy, color: .white),
                top: textTop, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.08, maxHeight: canvasWidth * 0.15
            )
        }
        withAlpha(Easing.out((time - 0.55) / 0.6) * (1 - exit)) {
            ComposeScreenshots.drawText(
                ComposeScreenshots.styled(captions[0].subheadline, size: canvasWidth * 0.045, weight: .medium, color: NSColor.white.withAlphaComponent(0.9)),
                top: textTop + canvasWidth * 0.16, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.1, maxHeight: canvasWidth * 0.13
            )
        }
    }

    private func drawDevice(_ footage: NSBitmapImageRep, tour: Double, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        let entrance = Easing.out((tour - Tour.footageStart + Self.deviceEntrance) / Self.deviceEntrance)
        let exit = Easing.inOut((tour - Tour.duration) / 0.6)
        let drop = CGFloat(1 - entrance + exit) * canvasHeight * 0.75
        guard drop < canvasHeight else { return }

        let screenWidth = canvasWidth * 0.72
        let screenHeight = screenWidth * CGFloat(footage.pixelsHigh) / CGFloat(footage.pixelsWide)
        let bezel = screenWidth * 0.03
        let frame = NSRect(
            x: (canvasWidth - screenWidth) / 2 - bezel,
            y: canvasHeight * 0.73 - screenHeight - bezel * 2 - drop,
            width: screenWidth + bezel * 2,
            height: screenHeight + bezel * 2
        )
        ComposeScreenshots.drawDevice(footage, frame: frame, bezel: bezel, cornerRatio: 0.13, canvasWidth: canvasWidth)
    }

    private func drawHeadline(tour: Double, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        guard tour >= Tour.footageStart, tour <= Tour.duration else { return }
        let caption = Tour.caption(at: tour, fadesOutAtEnd: true)
        let text = captions[caption.captionIndex]
        let size = canvasWidth * 0.08
        let top = canvasHeight * 0.05 + CGFloat(1 - caption.alpha) * 30
        withAlpha(caption.alpha) {
            let used = ComposeScreenshots.drawText(
                ComposeScreenshots.styled(text.headline, size: size, weight: .heavy, color: .white),
                top: top, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.07, maxHeight: size * 2.5
            )
            ComposeScreenshots.drawText(
                ComposeScreenshots.styled(text.subheadline, size: size * 0.45, weight: .medium, color: NSColor.white.withAlphaComponent(0.85)),
                top: top + used + size * 0.3, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.07, maxHeight: size * 1.3
            )
        }
    }

    private func drawOutro(at time: Double, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        guard time > 0.2 else { return }
        let appear = Easing.out((time - 0.2) / 0.7)
        let iconSize = canvasWidth * 0.28 * CGFloat(0.8 + 0.2 * appear)
        let centerY = canvasHeight * 0.64
        withAlpha(appear) {
            ComposeScreenshots.drawIcon(
                icon, in: NSRect(x: (canvasWidth - iconSize) / 2, y: centerY - iconSize / 2, width: iconSize, height: iconSize),
                canvasWidth: canvasWidth
            )
        }
        var top = canvasHeight - centerY + canvasWidth * 0.2
        withAlpha(Easing.out((time - 0.4) / 0.6)) {
            top += ComposeScreenshots.drawText(
                ComposeScreenshots.styled("Renewly", size: canvasWidth * 0.11, weight: .heavy, color: .white),
                top: top, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.08, maxHeight: canvasWidth * 0.15
            )
        }
        top += canvasWidth * 0.03
        withAlpha(Easing.out((time - 0.6) / 0.6)) {
            top += ComposeScreenshots.drawText(
                ComposeScreenshots.styled(captions[0].headline, size: canvasWidth * 0.062, weight: .bold, color: .white),
                top: top, width: canvasWidth, height: canvasHeight, margin: canvasWidth * 0.08, maxHeight: canvasWidth * 0.16
            )
        }
        top += canvasWidth * 0.06
        withAlpha(Easing.out((time - 0.9) / 0.6)) {
            drawPill(outro, top: top, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        }
    }

    private func drawPill(_ text: String, top: CGFloat, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        let label = ComposeScreenshots.styled(text, size: canvasWidth * 0.045, weight: .bold, color: Palette.indigo)
        let textSize = ComposeScreenshots.measure(label, width: canvasWidth * 0.8, alignment: .center)
        let padding = NSSize(width: canvasWidth * 0.06, height: canvasWidth * 0.028)
        let pill = NSRect(
            x: (canvasWidth - textSize.width) / 2 - padding.width,
            y: canvasHeight - top - textSize.height - padding.height * 2,
            width: textSize.width + padding.width * 2,
            height: textSize.height + padding.height * 2
        )
        NSColor.white.setFill()
        NSBezierPath(roundedRect: pill, xRadius: pill.height / 2, yRadius: pill.height / 2).fill()
        _ = ComposeScreenshots.drawText(
            label, top: top + padding.height, width: canvasWidth, height: canvasHeight,
            left: pill.minX + padding.width, textWidth: textSize.width, maxHeight: textSize.height + 4, alignment: .center
        )
    }
}
