import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted accession rule.
    final class WeightedAccessionRuleView {
        var codeText: String
        var titleText: String
        var facility: String
        var ratioText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, titleText: String, facility: String, ratioText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.facility = facility
            self.ratioText = ratioText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAccessionRuleView(_ item: WeightedAccessionRule) -> WeightedAccessionRuleView {
        return WeightedAccessionRuleView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            facility: item.facility,
            ratioText: String(format: "%.2f", item.ratio),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAccessionRuleViews(_ items: [WeightedAccessionRule]) -> [WeightedAccessionRuleView] {
        var views: [WeightedAccessionRuleView] = []
        for item in items {
            views.append(toWeightedAccessionRuleView(item))
        }
        return views
    }

    static func sumWeightedAccessionRuleView(_ view: WeightedAccessionRuleView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
