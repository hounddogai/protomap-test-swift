import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall draft.
    final class RecallDraftView {
        var code: String
        var titleText: String
        var archivedText: String
        var graceDays: String
        var unitText: String
        var descriptionText: String
        var name: String
        var statusLabel: String

        init(code: String, titleText: String, archivedText: String, graceDays: String, unitText: String, descriptionText: String, name: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.archivedText = archivedText
            self.graceDays = graceDays
            self.unitText = unitText
            self.descriptionText = descriptionText
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toRecallDraftView(_ item: RecallDraft) -> RecallDraftView {
        return RecallDraftView(
            code: item.code,
            titleText: item.title,
            archivedText: "\(item.archived)",
            graceDays: String(item.graceDays),
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallDraftViews(_ items: [RecallDraft]) -> [RecallDraftView] {
        var views: [RecallDraftView] = []
        for item in items {
            views.append(toRecallDraftView(item))
        }
        return views
    }

    static func sumRecallDraftView(_ view: RecallDraftView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
