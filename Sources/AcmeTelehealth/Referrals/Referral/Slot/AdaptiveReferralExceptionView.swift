import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive referral exception.
    final class AdaptiveReferralExceptionView {
        var code: String
        var titleText: String
        var approved: String
        var expiresAt: String
        var rate: String
        var ward: String
        var margin: String
        var allergy: String
        var locale: String
        var facilityText: String
        var statusLabel: String

        init(code: String, titleText: String, approved: String, expiresAt: String, rate: String, ward: String, margin: String, allergy: String, locale: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approved = approved
            self.expiresAt = expiresAt
            self.rate = rate
            self.ward = ward
            self.margin = margin
            self.allergy = allergy
            self.locale = locale
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveReferralExceptionView(_ item: AdaptiveReferralException) -> AdaptiveReferralExceptionView {
        return AdaptiveReferralExceptionView(
            code: item.code,
            titleText: item.title,
            approved: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            rate: String(format: "%.2f", item.rate),
            ward: item.ward,
            margin: String(format: "%.2f", item.margin),
            allergy: item.allergy,
            locale: item.locale,
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveReferralExceptionViews(_ items: [AdaptiveReferralException]) -> [AdaptiveReferralExceptionView] {
        var views: [AdaptiveReferralExceptionView] = []
        for item in items {
            views.append(toAdaptiveReferralExceptionView(item))
        }
        return views
    }

    static func sumAdaptiveReferralExceptionView(_ view: AdaptiveReferralExceptionView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedExpiresAt) + parsedRate + parsedMargin
    }
}
