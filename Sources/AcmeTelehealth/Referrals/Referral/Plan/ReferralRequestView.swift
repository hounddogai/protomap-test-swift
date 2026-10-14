import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral request.
    final class ReferralRequestView {
        var codeText: String
        var nameText: String
        var acuity: String
        var score: String
        var bedText: String
        var threshold: String
        var title: String
        var ratio: String
        var sequence: String
        var weight: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, acuity: String, score: String, bedText: String, threshold: String, title: String, ratio: String, sequence: String, weight: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.acuity = acuity
            self.score = score
            self.bedText = bedText
            self.threshold = threshold
            self.title = title
            self.ratio = ratio
            self.sequence = sequence
            self.weight = weight
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toReferralRequestView(_ item: ReferralRequest) -> ReferralRequestView {
        return ReferralRequestView(
            codeText: item.code,
            nameText: item.name,
            acuity: String(item.acuity),
            score: String(format: "%.2f", item.score),
            bedText: item.bed,
            threshold: String(format: "%.2f", item.threshold),
            title: Kit.Text.truncate(item.title, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            sequence: String(item.sequence),
            weight: String(format: "%.2f", item.weight),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralRequestViews(_ items: [ReferralRequest]) -> [ReferralRequestView] {
        var views: [ReferralRequestView] = []
        for item in items {
            views.append(toReferralRequestView(item))
        }
        return views
    }

    static func sumReferralRequestView(_ view: ReferralRequestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedAcuity) + parsedScore + parsedThreshold
    }
}
