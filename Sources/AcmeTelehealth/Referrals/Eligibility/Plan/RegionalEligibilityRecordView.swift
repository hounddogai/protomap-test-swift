import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional eligibility record.
    final class RegionalEligibilityRecordView {
        var codeText: String
        var labelText: String
        var rate: String
        var discount: String
        var categoryText: String
        var priorityText: String
        var titleText: String
        var graceDaysText: String
        var contactEmail: String
        var sourceText: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, labelText: String, rate: String, discount: String, categoryText: String, priorityText: String, titleText: String, graceDaysText: String, contactEmail: String, sourceText: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.rate = rate
            self.discount = discount
            self.categoryText = categoryText
            self.priorityText = priorityText
            self.titleText = titleText
            self.graceDaysText = graceDaysText
            self.contactEmail = contactEmail
            self.sourceText = sourceText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalEligibilityRecordView(_ item: RegionalEligibilityRecord) -> RegionalEligibilityRecordView {
        return RegionalEligibilityRecordView(
            codeText: item.code,
            labelText: item.label,
            rate: String(format: "%.2f", item.rate),
            discount: String(format: "%.2f", item.discount),
            categoryText: item.category,
            priorityText: String(item.priority),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            graceDaysText: String(item.graceDays),
            contactEmail: item.contactEmail,
            sourceText: item.source,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalEligibilityRecordViews(_ items: [RegionalEligibilityRecord]) -> [RegionalEligibilityRecordView] {
        var views: [RegionalEligibilityRecordView] = []
        for item in items {
            views.append(toRegionalEligibilityRecordView(item))
        }
        return views
    }

    static func sumRegionalEligibilityRecordView(_ view: RegionalEligibilityRecordView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedRate + parsedDiscount + Double(parsedPriority)
    }
}
