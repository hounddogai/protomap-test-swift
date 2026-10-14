import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary referral milestone.
    final class PrimaryReferralMilestoneView {
        var codeText: String
        var title: String
        var updatedAt: String
        var capacity: String
        var copay: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, title: String, updatedAt: String, capacity: String, copay: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.copay = copay
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryReferralMilestoneView(_ item: PrimaryReferralMilestone) -> PrimaryReferralMilestoneView {
        return PrimaryReferralMilestoneView(
            codeText: item.code,
            title: item.title,
            updatedAt: String(item.updatedAt),
            capacity: String(item.capacity),
            copay: String(format: "%.2f", item.copay),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryReferralMilestoneViews(_ items: [PrimaryReferralMilestone]) -> [PrimaryReferralMilestoneView] {
        var views: [PrimaryReferralMilestoneView] = []
        for item in items {
            views.append(toPrimaryReferralMilestoneView(item))
        }
        return views
    }

    static func sumPrimaryReferralMilestoneView(_ view: PrimaryReferralMilestoneView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCapacity) + parsedCopay
    }
}
