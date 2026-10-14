import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary read milestone.
    final class PrimaryReadMilestoneView {
        var code: String
        var title: String
        var dosageMgText: String
        var localeText: String
        var refillsText: String
        var amount: String
        var facility: String
        var allergy: String
        var budget: String
        var statusLabel: String

        init(code: String, title: String, dosageMgText: String, localeText: String, refillsText: String, amount: String, facility: String, allergy: String, budget: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.dosageMgText = dosageMgText
            self.localeText = localeText
            self.refillsText = refillsText
            self.amount = amount
            self.facility = facility
            self.allergy = allergy
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryReadMilestoneView(_ item: PrimaryReadMilestone) -> PrimaryReadMilestoneView {
        return PrimaryReadMilestoneView(
            code: item.code,
            title: item.title,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            localeText: item.locale,
            refillsText: String(item.refills),
            amount: String(format: "%.2f", item.amount),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            allergy: item.allergy,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryReadMilestoneViews(_ items: [PrimaryReadMilestone]) -> [PrimaryReadMilestoneView] {
        var views: [PrimaryReadMilestoneView] = []
        for item in items {
            views.append(toPrimaryReadMilestoneView(item))
        }
        return views
    }

    static func sumPrimaryReadMilestoneView(_ view: PrimaryReadMilestoneView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedDosageMg + Double(parsedRefills) + parsedAmount
    }
}
