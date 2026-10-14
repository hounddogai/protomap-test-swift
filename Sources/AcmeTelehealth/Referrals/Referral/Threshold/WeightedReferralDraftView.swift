import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted referral draft.
    final class WeightedReferralDraftView {
        var code: String
        var label: String
        var expiresAtText: String
        var score: String
        var name: String
        var visibleText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, expiresAtText: String, score: String, name: String, visibleText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAtText = expiresAtText
            self.score = score
            self.name = name
            self.visibleText = visibleText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReferralDraftView(_ item: WeightedReferralDraft) -> WeightedReferralDraftView {
        return WeightedReferralDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 80),
            expiresAtText: String(item.expiresAt),
            score: String(format: "%.2f", item.score),
            name: Kit.Text.truncate(item.name, limit: 64),
            visibleText: "\(item.visible)",
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReferralDraftViews(_ items: [WeightedReferralDraft]) -> [WeightedReferralDraftView] {
        var views: [WeightedReferralDraftView] = []
        for item in items {
            views.append(toWeightedReferralDraftView(item))
        }
        return views
    }

    static func sumWeightedReferralDraftView(_ view: WeightedReferralDraftView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedExpiresAt) + parsedScore
    }
}
