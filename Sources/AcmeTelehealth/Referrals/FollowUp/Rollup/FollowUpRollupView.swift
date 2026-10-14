import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up rollup.
    final class FollowUpRollupView {
        var code: String
        var titleText: String
        var name: String
        var pinnedText: String
        var reviewerText: String
        var notes: String
        var quantityText: String
        var visible: String
        var statusLabel: String

        init(code: String, titleText: String, name: String, pinnedText: String, reviewerText: String, notes: String, quantityText: String, visible: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.name = name
            self.pinnedText = pinnedText
            self.reviewerText = reviewerText
            self.notes = notes
            self.quantityText = quantityText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpRollupView(_ item: FollowUpRollup) -> FollowUpRollupView {
        return FollowUpRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            name: item.name,
            pinnedText: "\(item.pinned)",
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            quantityText: String(item.quantity),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpRollupViews(_ items: [FollowUpRollup]) -> [FollowUpRollupView] {
        var views: [FollowUpRollupView] = []
        for item in items {
            views.append(toFollowUpRollupView(item))
        }
        return views
    }

    static func sumFollowUpRollupView(_ view: FollowUpRollupView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
