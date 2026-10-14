import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched referral assignment.
    final class BatchedReferralAssignmentView {
        var code: String
        var label: String
        var versionText: String
        var sourceText: String
        var reviewerText: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, label: String, versionText: String, sourceText: String, reviewerText: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.versionText = versionText
            self.sourceText = sourceText
            self.reviewerText = reviewerText
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedReferralAssignmentView(_ item: BatchedReferralAssignment) -> BatchedReferralAssignmentView {
        return BatchedReferralAssignmentView(
            code: item.code,
            label: item.label,
            versionText: String(item.version),
            sourceText: item.source,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedReferralAssignmentViews(_ items: [BatchedReferralAssignment]) -> [BatchedReferralAssignmentView] {
        var views: [BatchedReferralAssignmentView] = []
        for item in items {
            views.append(toBatchedReferralAssignmentView(item))
        }
        return views
    }

    static func sumBatchedReferralAssignmentView(_ view: BatchedReferralAssignmentView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
