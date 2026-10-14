import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot claim.
    final class SlotClaimView {
        var codeText: String
        var title: String
        var ratioText: String
        var copay: String
        var budget: String
        var facility: String
        var statusLabel: String

        init(codeText: String, title: String, ratioText: String, copay: String, budget: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ratioText = ratioText
            self.copay = copay
            self.budget = budget
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toSlotClaimView(_ item: SlotClaim) -> SlotClaimView {
        return SlotClaimView(
            codeText: item.code,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            copay: String(format: "%.2f", item.copay),
            budget: String(format: "%.2f", item.budget),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotClaimViews(_ items: [SlotClaim]) -> [SlotClaimView] {
        var views: [SlotClaimView] = []
        for item in items {
            views.append(toSlotClaimView(item))
        }
        return views
    }

    static func sumSlotClaimView(_ view: SlotClaimView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRatio + parsedCopay + parsedBudget
    }
}
