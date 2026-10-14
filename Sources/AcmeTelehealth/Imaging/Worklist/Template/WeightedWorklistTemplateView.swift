import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted worklist template.
    final class WeightedWorklistTemplateView {
        var code: String
        var titleText: String
        var quantity: String
        var retries: String
        var refillsText: String
        var countryText: String
        var approved: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, titleText: String, quantity: String, retries: String, refillsText: String, countryText: String, approved: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.quantity = quantity
            self.retries = retries
            self.refillsText = refillsText
            self.countryText = countryText
            self.approved = approved
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedWorklistTemplateView(_ item: WeightedWorklistTemplate) -> WeightedWorklistTemplateView {
        return WeightedWorklistTemplateView(
            code: item.code,
            titleText: item.title,
            quantity: String(item.quantity),
            retries: String(item.retries),
            refillsText: String(item.refills),
            countryText: Kit.Text.truncate(item.country, limit: 120),
            approved: "\(item.approved)",
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedWorklistTemplateViews(_ items: [WeightedWorklistTemplate]) -> [WeightedWorklistTemplateView] {
        var views: [WeightedWorklistTemplateView] = []
        for item in items {
            views.append(toWeightedWorklistTemplateView(item))
        }
        return views
    }

    static func sumWeightedWorklistTemplateView(_ view: WeightedWorklistTemplateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRetries) + Double(parsedRefills)
    }
}
