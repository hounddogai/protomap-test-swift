import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive bed board batch.
    final class AdaptiveBedBoardBatchView {
        var codeText: String
        var name: String
        var durationMinutesText: String
        var segmentText: String
        var sequence: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, name: String, durationMinutesText: String, segmentText: String, sequence: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.durationMinutesText = durationMinutesText
            self.segmentText = segmentText
            self.sequence = sequence
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveBedBoardBatchView(_ item: AdaptiveBedBoardBatch) -> AdaptiveBedBoardBatchView {
        return AdaptiveBedBoardBatchView(
            codeText: item.code,
            name: item.name,
            durationMinutesText: String(item.durationMinutes),
            segmentText: Kit.Text.truncate(item.segment, limit: 120),
            sequence: String(item.sequence),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveBedBoardBatchViews(_ items: [AdaptiveBedBoardBatch]) -> [AdaptiveBedBoardBatchView] {
        var views: [AdaptiveBedBoardBatchView] = []
        for item in items {
            views.append(toAdaptiveBedBoardBatchView(item))
        }
        return views
    }

    static func sumAdaptiveBedBoardBatchView(_ view: AdaptiveBedBoardBatchView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedSequence) + parsedRatio
    }
}
