import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read draft.
    final class ReadDraftView {
        var code: String
        var label: String
        var updatedAt: String
        var name: String
        var externalRef: String
        var titleText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, name: String, externalRef: String, titleText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.name = name
            self.externalRef = externalRef
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toReadDraftView(_ item: ReadDraft) -> ReadDraftView {
        return ReadDraftView(
            code: item.code,
            label: item.label,
            updatedAt: String(item.updatedAt),
            name: item.name,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            titleText: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadDraftViews(_ items: [ReadDraft]) -> [ReadDraftView] {
        var views: [ReadDraftView] = []
        for item in items {
            views.append(toReadDraftView(item))
        }
        return views
    }

    static func sumReadDraftView(_ view: ReadDraftView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
