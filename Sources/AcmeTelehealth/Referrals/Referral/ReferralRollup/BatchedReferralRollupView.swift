import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched referral rollup.
    final class BatchedReferralRollupView {
        var codeText: String
        var label: String
        var reviewer: String
        var retries: String
        var procedureCode: String
        var facility: String
        var score: String
        var limitText: String
        var threshold: String
        var refills: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, label: String, reviewer: String, retries: String, procedureCode: String, facility: String, score: String, limitText: String, threshold: String, refills: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.reviewer = reviewer
            self.retries = retries
            self.procedureCode = procedureCode
            self.facility = facility
            self.score = score
            self.limitText = limitText
            self.threshold = threshold
            self.refills = refills
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedReferralRollupView(_ item: BatchedReferralRollup) -> BatchedReferralRollupView {
        return BatchedReferralRollupView(
            codeText: item.code,
            label: item.label,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            retries: String(item.retries),
            procedureCode: item.procedureCode,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            score: String(format: "%.2f", item.score),
            limitText: String(item.limit),
            threshold: String(format: "%.2f", item.threshold),
            refills: String(item.refills),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedReferralRollupViews(_ items: [BatchedReferralRollup]) -> [BatchedReferralRollupView] {
        var views: [BatchedReferralRollupView] = []
        for item in items {
            views.append(toBatchedReferralRollupView(item))
        }
        return views
    }

    static func sumBatchedReferralRollupView(_ view: BatchedReferralRollupView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRetries) + parsedScore + Double(parsedLimit)
    }
}
