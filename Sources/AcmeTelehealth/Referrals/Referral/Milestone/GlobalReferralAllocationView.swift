import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global referral allocation.
    final class GlobalReferralAllocationView {
        var code: String
        var label: String
        var segment: String
        var expiresAt: String
        var revision: String
        var active: String
        var name: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, segment: String, expiresAt: String, revision: String, active: String, name: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.expiresAt = expiresAt
            self.revision = revision
            self.active = active
            self.name = name
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferralAllocationView(_ item: GlobalReferralAllocation) -> GlobalReferralAllocationView {
        return GlobalReferralAllocationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            segment: item.segment,
            expiresAt: String(item.expiresAt),
            revision: String(item.revision),
            active: "\(item.active)",
            name: item.name,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferralAllocationViews(_ items: [GlobalReferralAllocation]) -> [GlobalReferralAllocationView] {
        var views: [GlobalReferralAllocationView] = []
        for item in items {
            views.append(toGlobalReferralAllocationView(item))
        }
        return views
    }

    static func sumGlobalReferralAllocationView(_ view: GlobalReferralAllocationView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedRevision) + Double(parsedStartsAt)
    }
}
