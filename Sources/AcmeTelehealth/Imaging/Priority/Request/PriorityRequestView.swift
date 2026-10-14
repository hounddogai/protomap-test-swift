import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority request.
    final class PriorityRequestView {
        var code: String
        var name: String
        var budgetText: String
        var country: String
        var summaryText: String
        var discount: String
        var limitText: String
        var diagnosisCode: String
        var allergyText: String
        var statusLabel: String

        init(code: String, name: String, budgetText: String, country: String, summaryText: String, discount: String, limitText: String, diagnosisCode: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budgetText = budgetText
            self.country = country
            self.summaryText = summaryText
            self.discount = discount
            self.limitText = limitText
            self.diagnosisCode = diagnosisCode
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityRequestView(_ item: PriorityRequest) -> PriorityRequestView {
        return PriorityRequestView(
            code: item.code,
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            country: item.country,
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            discount: String(format: "%.2f", item.discount),
            limitText: String(item.limit),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityRequestViews(_ items: [PriorityRequest]) -> [PriorityRequestView] {
        var views: [PriorityRequestView] = []
        for item in items {
            views.append(toPriorityRequestView(item))
        }
        return views
    }

    static func sumPriorityRequestView(_ view: PriorityRequestView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedBudget + parsedDiscount + Double(parsedLimit)
    }
}
