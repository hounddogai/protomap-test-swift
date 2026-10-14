import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning draft.
    final class CleaningDraftView {
        var codeText: String
        var title: String
        var archived: String
        var versionText: String
        var limit: String
        var statusLabel: String

        init(codeText: String, title: String, archived: String, versionText: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.archived = archived
            self.versionText = versionText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningDraftView(_ item: CleaningDraft) -> CleaningDraftView {
        return CleaningDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            archived: "\(item.archived)",
            versionText: String(item.version),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningDraftViews(_ items: [CleaningDraft]) -> [CleaningDraftView] {
        var views: [CleaningDraftView] = []
        for item in items {
            views.append(toCleaningDraftView(item))
        }
        return views
    }

    static func sumCleaningDraftView(_ view: CleaningDraftView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit)
    }
}
