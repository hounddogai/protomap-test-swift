import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional study snapshot.
    final class RegionalStudySnapshotView {
        var code: String
        var name: String
        var labelText: String
        var endsAtText: String
        var archived: String
        var statusLabel: String

        init(code: String, name: String, labelText: String, endsAtText: String, archived: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.labelText = labelText
            self.endsAtText = endsAtText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStudySnapshotView(_ item: RegionalStudySnapshot) -> RegionalStudySnapshotView {
        return RegionalStudySnapshotView(
            code: item.code,
            name: item.name,
            labelText: item.label,
            endsAtText: String(item.endsAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStudySnapshotViews(_ items: [RegionalStudySnapshot]) -> [RegionalStudySnapshotView] {
        var views: [RegionalStudySnapshotView] = []
        for item in items {
            views.append(toRegionalStudySnapshotView(item))
        }
        return views
    }

    static func sumRegionalStudySnapshotView(_ view: RegionalStudySnapshotView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
