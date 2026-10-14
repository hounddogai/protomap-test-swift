import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority snapshot.
    final class PrioritySnapshotView {
        var codeText: String
        var label: String
        var ratio: String
        var contactEmail: String
        var dosageMg: String
        var source: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, label: String, ratio: String, contactEmail: String, dosageMg: String, source: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.source = source
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toPrioritySnapshotView(_ item: PrioritySnapshot) -> PrioritySnapshotView {
        return PrioritySnapshotView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            source: Kit.Text.truncate(item.source, limit: 64),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrioritySnapshotViews(_ items: [PrioritySnapshot]) -> [PrioritySnapshotView] {
        var views: [PrioritySnapshotView] = []
        for item in items {
            views.append(toPrioritySnapshotView(item))
        }
        return views
    }

    static func sumPrioritySnapshotView(_ view: PrioritySnapshotView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedRatio + parsedDosageMg
    }
}
