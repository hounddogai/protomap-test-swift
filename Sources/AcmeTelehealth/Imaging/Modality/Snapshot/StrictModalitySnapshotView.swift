import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict modality snapshot.
    final class StrictModalitySnapshotView {
        var code: String
        var labelText: String
        var floorValue: String
        var batchSizeText: String
        var category: String
        var active: String
        var notes: String
        var score: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, batchSizeText: String, category: String, active: String, notes: String, score: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.batchSizeText = batchSizeText
            self.category = category
            self.active = active
            self.notes = notes
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toStrictModalitySnapshotView(_ item: StrictModalitySnapshot) -> StrictModalitySnapshotView {
        return StrictModalitySnapshotView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            batchSizeText: String(item.batchSize),
            category: item.category,
            active: "\(item.active)",
            notes: item.notes,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictModalitySnapshotViews(_ items: [StrictModalitySnapshot]) -> [StrictModalitySnapshotView] {
        var views: [StrictModalitySnapshotView] = []
        for item in items {
            views.append(toStrictModalitySnapshotView(item))
        }
        return views
    }

    static func sumStrictModalitySnapshotView(_ view: StrictModalitySnapshotView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedFloorValue + Double(parsedBatchSize) + parsedScore
    }
}
