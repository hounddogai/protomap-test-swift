import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession snapshot.
    final class AccessionSnapshotView {
        var code: String
        var title: String
        var revision: String
        var externalRefText: String
        var notes: String
        var copay: String
        var dosageMg: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, revision: String, externalRefText: String, notes: String, copay: String, dosageMg: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.externalRefText = externalRefText
            self.notes = notes
            self.copay = copay
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionSnapshotView(_ item: AccessionSnapshot) -> AccessionSnapshotView {
        return AccessionSnapshotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            revision: String(item.revision),
            externalRefText: item.externalRef,
            notes: item.notes,
            copay: String(format: "%.2f", item.copay),
            dosageMg: String(format: "%.2f", item.dosageMg),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionSnapshotViews(_ items: [AccessionSnapshot]) -> [AccessionSnapshotView] {
        var views: [AccessionSnapshotView] = []
        for item in items {
            views.append(toAccessionSnapshotView(item))
        }
        return views
    }

    static func sumAccessionSnapshotView(_ view: AccessionSnapshotView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRevision) + parsedCopay + parsedDosageMg
    }
}
