import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen snapshot.
    final class SpecimenSnapshotView {
        var code: String
        var title: String
        var notes: String
        var active: String
        var currency: String
        var batchSize: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, notes: String, active: String, currency: String, batchSize: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.active = active
            self.currency = currency
            self.batchSize = batchSize
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenSnapshotView(_ item: SpecimenSnapshot) -> SpecimenSnapshotView {
        return SpecimenSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            notes: item.notes,
            active: "\(item.active)",
            currency: item.currency,
            batchSize: String(item.batchSize),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenSnapshotViews(_ items: [SpecimenSnapshot]) -> [SpecimenSnapshotView] {
        var views: [SpecimenSnapshotView] = []
        for item in items {
            views.append(toSpecimenSnapshotView(item))
        }
        return views
    }

    static func sumSpecimenSnapshotView(_ view: SpecimenSnapshotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
