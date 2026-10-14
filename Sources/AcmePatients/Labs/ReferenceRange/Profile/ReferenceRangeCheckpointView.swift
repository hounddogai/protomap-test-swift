import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range checkpoint.
    final class ReferenceRangeCheckpointView {
        var code: String
        var name: String
        var durationMinutes: String
        var sequenceText: String
        var startsAt: String
        var segment: String
        var discount: String
        var floorValue: String
        var visible: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, sequenceText: String, startsAt: String, segment: String, discount: String, floorValue: String, visible: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.sequenceText = sequenceText
            self.startsAt = startsAt
            self.segment = segment
            self.discount = discount
            self.floorValue = floorValue
            self.visible = visible
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeCheckpointView(_ item: ReferenceRangeCheckpoint) -> ReferenceRangeCheckpointView {
        return ReferenceRangeCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            durationMinutes: String(item.durationMinutes),
            sequenceText: String(item.sequence),
            startsAt: String(item.startsAt),
            segment: item.segment,
            discount: String(format: "%.2f", item.discount),
            floorValue: String(format: "%.2f", item.floorValue),
            visible: "\(item.visible)",
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeCheckpointViews(_ items: [ReferenceRangeCheckpoint]) -> [ReferenceRangeCheckpointView] {
        var views: [ReferenceRangeCheckpointView] = []
        for item in items {
            views.append(toReferenceRangeCheckpointView(item))
        }
        return views
    }

    static func sumReferenceRangeCheckpointView(_ view: ReferenceRangeCheckpointView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedSequence) + Double(parsedStartsAt)
    }
}
