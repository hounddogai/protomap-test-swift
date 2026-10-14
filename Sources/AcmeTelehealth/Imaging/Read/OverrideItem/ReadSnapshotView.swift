import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read snapshot.
    final class ReadSnapshotView {
        var code: String
        var title: String
        var procedureCode: String
        var specialtyText: String
        var revision: String
        var contactEmailText: String
        var reviewer: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, specialtyText: String, revision: String, contactEmailText: String, reviewer: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.specialtyText = specialtyText
            self.revision = revision
            self.contactEmailText = contactEmailText
            self.reviewer = reviewer
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toReadSnapshotView(_ item: ReadSnapshot) -> ReadSnapshotView {
        return ReadSnapshotView(
            code: item.code,
            title: item.title,
            procedureCode: item.procedureCode,
            specialtyText: item.specialty,
            revision: String(item.revision),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            reviewer: item.reviewer,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadSnapshotViews(_ items: [ReadSnapshot]) -> [ReadSnapshotView] {
        var views: [ReadSnapshotView] = []
        for item in items {
            views.append(toReadSnapshotView(item))
        }
        return views
    }

    static func sumReadSnapshotView(_ view: ReadSnapshotView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
