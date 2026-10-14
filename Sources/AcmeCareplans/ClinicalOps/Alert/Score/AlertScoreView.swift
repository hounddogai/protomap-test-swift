import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert score.
    final class AlertScoreView {
        var code: String
        var title: String
        var retriesText: String
        var categoryText: String
        var capacity: String
        var country: String
        var patientRefText: String
        var budgetText: String
        var statusLabel: String

        init(code: String, title: String, retriesText: String, categoryText: String, capacity: String, country: String, patientRefText: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retriesText = retriesText
            self.categoryText = categoryText
            self.capacity = capacity
            self.country = country
            self.patientRefText = patientRefText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertScoreView(_ item: AlertScore) -> AlertScoreView {
        return AlertScoreView(
            code: item.code,
            title: item.title,
            retriesText: String(item.retries),
            categoryText: item.category,
            capacity: String(item.capacity),
            country: Kit.Text.truncate(item.country, limit: 64),
            patientRefText: item.patientRef,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertScoreViews(_ items: [AlertScore]) -> [AlertScoreView] {
        var views: [AlertScoreView] = []
        for item in items {
            views.append(toAlertScoreView(item))
        }
        return views
    }

    static func sumAlertScoreView(_ view: AlertScoreView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRetries) + Double(parsedCapacity) + parsedBudget
    }
}
