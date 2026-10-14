import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling denial rule.
    final class RollingDenialRuleView {
        var code: String
        var title: String
        var createdAt: String
        var phoneText: String
        var visitMinutes: String
        var startsAt: String
        var countryText: String
        var discount: String
        var externalRefText: String
        var specialtyText: String
        var categoryText: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, phoneText: String, visitMinutes: String, startsAt: String, countryText: String, discount: String, externalRefText: String, specialtyText: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.phoneText = phoneText
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.countryText = countryText
            self.discount = discount
            self.externalRefText = externalRefText
            self.specialtyText = specialtyText
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDenialRuleView(_ item: RollingDenialRule) -> RollingDenialRuleView {
        return RollingDenialRuleView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            phoneText: item.phone,
            visitMinutes: String(item.visitMinutes),
            startsAt: String(item.startsAt),
            countryText: item.country,
            discount: String(format: "%.2f", item.discount),
            externalRefText: item.externalRef,
            specialtyText: item.specialty,
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDenialRuleViews(_ items: [RollingDenialRule]) -> [RollingDenialRuleView] {
        var views: [RollingDenialRuleView] = []
        for item in items {
            views.append(toRollingDenialRuleView(item))
        }
        return views
    }

    static func sumRollingDenialRuleView(_ view: RollingDenialRuleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes) + Double(parsedStartsAt)
    }
}
