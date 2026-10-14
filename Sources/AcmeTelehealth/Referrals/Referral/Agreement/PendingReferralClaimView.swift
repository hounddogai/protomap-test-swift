import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending referral claim.
    final class PendingReferralClaimView {
        var code: String
        var name: String
        var sequenceText: String
        var limitText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, sequenceText: String, limitText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequenceText = sequenceText
            self.limitText = limitText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferralClaimView(_ item: PendingReferralClaim) -> PendingReferralClaimView {
        return PendingReferralClaimView(
            code: item.code,
            name: item.name,
            sequenceText: String(item.sequence),
            limitText: String(item.limit),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferralClaimViews(_ items: [PendingReferralClaim]) -> [PendingReferralClaimView] {
        var views: [PendingReferralClaimView] = []
        for item in items {
            views.append(toPendingReferralClaimView(item))
        }
        return views
    }

    static func sumPendingReferralClaimView(_ view: PendingReferralClaimView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedSequence) + Double(parsedLimit) + Double(parsedBatchSize)
    }
}
