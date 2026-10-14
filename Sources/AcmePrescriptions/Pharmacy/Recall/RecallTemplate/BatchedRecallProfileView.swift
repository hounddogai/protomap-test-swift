import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched recall profile.
    final class BatchedRecallProfileView {
        var code: String
        var label: String
        var sequence: String
        var durationMinutesText: String
        var pinnedText: String
        var floorValueText: String
        var description: String
        var startsAt: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, sequence: String, durationMinutesText: String, pinnedText: String, floorValueText: String, description: String, startsAt: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.durationMinutesText = durationMinutesText
            self.pinnedText = pinnedText
            self.floorValueText = floorValueText
            self.description = description
            self.startsAt = startsAt
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRecallProfileView(_ item: BatchedRecallProfile) -> BatchedRecallProfileView {
        return BatchedRecallProfileView(
            code: item.code,
            label: item.label,
            sequence: String(item.sequence),
            durationMinutesText: String(item.durationMinutes),
            pinnedText: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            description: item.description,
            startsAt: String(item.startsAt),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRecallProfileViews(_ items: [BatchedRecallProfile]) -> [BatchedRecallProfileView] {
        var views: [BatchedRecallProfileView] = []
        for item in items {
            views.append(toBatchedRecallProfileView(item))
        }
        return views
    }

    static func sumBatchedRecallProfileView(_ view: BatchedRecallProfileView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedSequence) + Double(parsedDurationMinutes) + parsedFloorValue
    }
}
