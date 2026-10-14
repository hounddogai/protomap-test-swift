import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach budget.
    final class OutreachBudgetView {
        var code: String
        var titleText: String
        var reviewerText: String
        var timezone: String
        var locale: String
        var amountText: String
        var specialty: String
        var checksum: String
        var region: String
        var categoryText: String
        var statusLabel: String

        init(code: String, titleText: String, reviewerText: String, timezone: String, locale: String, amountText: String, specialty: String, checksum: String, region: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.reviewerText = reviewerText
            self.timezone = timezone
            self.locale = locale
            self.amountText = amountText
            self.specialty = specialty
            self.checksum = checksum
            self.region = region
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachBudgetView(_ item: OutreachBudget) -> OutreachBudgetView {
        return OutreachBudgetView(
            code: item.code,
            titleText: item.title,
            reviewerText: item.reviewer,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            locale: item.locale,
            amountText: String(format: "%.2f", item.amount),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            region: item.region,
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachBudgetViews(_ items: [OutreachBudget]) -> [OutreachBudgetView] {
        var views: [OutreachBudgetView] = []
        for item in items {
            views.append(toOutreachBudgetView(item))
        }
        return views
    }

    static func sumOutreachBudgetView(_ view: OutreachBudgetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
