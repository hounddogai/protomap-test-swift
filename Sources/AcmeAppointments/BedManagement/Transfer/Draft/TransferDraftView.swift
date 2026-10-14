import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer draft.
    final class TransferDraftView {
        var code: String
        var name: String
        var title: String
        var category: String
        var score: String
        var statusLabel: String

        init(code: String, name: String, title: String, category: String, score: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.category = category
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTransferDraftView(_ item: TransferDraft) -> TransferDraftView {
        return TransferDraftView(
            code: item.code,
            name: item.name,
            title: item.title,
            category: item.category,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferDraftViews(_ items: [TransferDraft]) -> [TransferDraftView] {
        var views: [TransferDraftView] = []
        for item in items {
            views.append(toTransferDraftView(item))
        }
        return views
    }

    static func sumTransferDraftView(_ view: TransferDraftView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
