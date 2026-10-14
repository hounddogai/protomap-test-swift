import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered network digest.
    final class TieredNetworkDigestView {
        var codeText: String
        var name: String
        var channelText: String
        var acuityText: String
        var score: String
        var dosageMgText: String
        var startsAt: String
        var payerText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, name: String, channelText: String, acuityText: String, score: String, dosageMgText: String, startsAt: String, payerText: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.channelText = channelText
            self.acuityText = acuityText
            self.score = score
            self.dosageMgText = dosageMgText
            self.startsAt = startsAt
            self.payerText = payerText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredNetworkDigestView(_ item: TieredNetworkDigest) -> TieredNetworkDigestView {
        return TieredNetworkDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 40),
            channelText: item.channel,
            acuityText: String(item.acuity),
            score: String(format: "%.2f", item.score),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            startsAt: String(item.startsAt),
            payerText: item.payer,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredNetworkDigestViews(_ items: [TieredNetworkDigest]) -> [TieredNetworkDigestView] {
        var views: [TieredNetworkDigestView] = []
        for item in items {
            views.append(toTieredNetworkDigestView(item))
        }
        return views
    }

    static func sumTieredNetworkDigestView(_ view: TieredNetworkDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAcuity) + parsedScore + parsedDosageMg
    }
}
