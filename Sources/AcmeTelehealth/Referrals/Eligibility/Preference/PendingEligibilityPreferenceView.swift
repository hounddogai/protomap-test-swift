import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending eligibility preference.
    final class PendingEligibilityPreferenceView {
        var code: String
        var title: String
        var phone: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, phone: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toPendingEligibilityPreferenceView(_ item: PendingEligibilityPreference) -> PendingEligibilityPreferenceView {
        return PendingEligibilityPreferenceView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingEligibilityPreferenceViews(_ items: [PendingEligibilityPreference]) -> [PendingEligibilityPreferenceView] {
        var views: [PendingEligibilityPreferenceView] = []
        for item in items {
            views.append(toPendingEligibilityPreferenceView(item))
        }
        return views
    }

    static func sumPendingEligibilityPreferenceView(_ view: PendingEligibilityPreferenceView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
