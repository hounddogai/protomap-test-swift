import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted risk score template.
    final class WeightedRiskScoreTemplateView {
        var code: String
        var nameText: String
        var channel: String
        var title: String
        var allergy: String
        var startsAt: String
        var expiresAt: String
        var budget: String
        var statusLabel: String

        init(code: String, nameText: String, channel: String, title: String, allergy: String, startsAt: String, expiresAt: String, budget: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.channel = channel
            self.title = title
            self.allergy = allergy
            self.startsAt = startsAt
            self.expiresAt = expiresAt
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRiskScoreTemplateView(_ item: WeightedRiskScoreTemplate) -> WeightedRiskScoreTemplateView {
        return WeightedRiskScoreTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            channel: item.channel,
            title: item.title,
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            startsAt: String(item.startsAt),
            expiresAt: String(item.expiresAt),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRiskScoreTemplateViews(_ items: [WeightedRiskScoreTemplate]) -> [WeightedRiskScoreTemplateView] {
        var views: [WeightedRiskScoreTemplateView] = []
        for item in items {
            views.append(toWeightedRiskScoreTemplateView(item))
        }
        return views
    }

    static func sumWeightedRiskScoreTemplateView(_ view: WeightedRiskScoreTemplateView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedExpiresAt) + parsedBudget
    }
}
