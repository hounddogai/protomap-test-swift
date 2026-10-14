import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional authorization allocation.
    final class RegionalAuthorizationAllocationView {
        var code: String
        var label: String
        var discount: String
        var wardText: String
        var phone: String
        var reviewerText: String
        var durationMinutes: String
        var maximum: String
        var categoryText: String
        var statusLabel: String

        init(code: String, label: String, discount: String, wardText: String, phone: String, reviewerText: String, durationMinutes: String, maximum: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.wardText = wardText
            self.phone = phone
            self.reviewerText = reviewerText
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAuthorizationAllocationView(_ item: RegionalAuthorizationAllocation) -> RegionalAuthorizationAllocationView {
        return RegionalAuthorizationAllocationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            phone: item.phone,
            reviewerText: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            maximum: String(format: "%.2f", item.maximum),
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAuthorizationAllocationViews(_ items: [RegionalAuthorizationAllocation]) -> [RegionalAuthorizationAllocationView] {
        var views: [RegionalAuthorizationAllocationView] = []
        for item in items {
            views.append(toRegionalAuthorizationAllocationView(item))
        }
        return views
    }

    static func sumRegionalAuthorizationAllocationView(_ view: RegionalAuthorizationAllocationView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedDiscount + Double(parsedDurationMinutes) + parsedMaximum
    }
}
