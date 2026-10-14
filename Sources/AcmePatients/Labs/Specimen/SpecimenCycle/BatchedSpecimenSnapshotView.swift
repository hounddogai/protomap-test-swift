import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched specimen snapshot.
    final class BatchedSpecimenSnapshotView {
        var code: String
        var nameText: String
        var activeText: String
        var copay: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, nameText: String, activeText: String, copay: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.activeText = activeText
            self.copay = copay
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSpecimenSnapshotView(_ item: BatchedSpecimenSnapshot) -> BatchedSpecimenSnapshotView {
        return BatchedSpecimenSnapshotView(
            code: item.code,
            nameText: item.name,
            activeText: "\(item.active)",
            copay: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSpecimenSnapshotViews(_ items: [BatchedSpecimenSnapshot]) -> [BatchedSpecimenSnapshotView] {
        var views: [BatchedSpecimenSnapshotView] = []
        for item in items {
            views.append(toBatchedSpecimenSnapshotView(item))
        }
        return views
    }

    static func sumBatchedSpecimenSnapshotView(_ view: BatchedSpecimenSnapshotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCopay + parsedDosageMg
    }
}
