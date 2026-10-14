import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global referral cycle.
    final class GlobalReferralCycleView {
        var codeText: String
        var titleText: String
        var endsAt: String
        var durationMinutes: String
        var patientRefText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, titleText: String, endsAt: String, durationMinutes: String, patientRefText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.patientRefText = patientRefText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferralCycleView(_ item: GlobalReferralCycle) -> GlobalReferralCycleView {
        return GlobalReferralCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            endsAt: String(item.endsAt),
            durationMinutes: String(item.durationMinutes),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferralCycleViews(_ items: [GlobalReferralCycle]) -> [GlobalReferralCycleView] {
        var views: [GlobalReferralCycleView] = []
        for item in items {
            views.append(toGlobalReferralCycleView(item))
        }
        return views
    }

    static func sumGlobalReferralCycleView(_ view: GlobalReferralCycleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedDurationMinutes)
    }
}
