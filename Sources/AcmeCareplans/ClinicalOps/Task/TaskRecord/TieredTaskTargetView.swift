import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered task target.
    final class TieredTaskTargetView {
        var code: String
        var nameText: String
        var endsAtText: String
        var bedText: String
        var contactEmail: String
        var limitText: String
        var facility: String
        var budgetText: String
        var quantity: String
        var statusLabel: String

        init(code: String, nameText: String, endsAtText: String, bedText: String, contactEmail: String, limitText: String, facility: String, budgetText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.endsAtText = endsAtText
            self.bedText = bedText
            self.contactEmail = contactEmail
            self.limitText = limitText
            self.facility = facility
            self.budgetText = budgetText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTaskTargetView(_ item: TieredTaskTarget) -> TieredTaskTargetView {
        return TieredTaskTargetView(
            code: item.code,
            nameText: item.name,
            endsAtText: String(item.endsAt),
            bedText: item.bed,
            contactEmail: item.contactEmail,
            limitText: String(item.limit),
            facility: item.facility,
            budgetText: String(format: "%.2f", item.budget),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTaskTargetViews(_ items: [TieredTaskTarget]) -> [TieredTaskTargetView] {
        var views: [TieredTaskTargetView] = []
        for item in items {
            views.append(toTieredTaskTargetView(item))
        }
        return views
    }

    static func sumTieredTaskTargetView(_ view: TieredTaskTargetView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedLimit) + parsedBudget
    }
}
