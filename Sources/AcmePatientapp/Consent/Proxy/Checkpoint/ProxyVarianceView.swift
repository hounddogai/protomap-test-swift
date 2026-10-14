import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy variance.
    final class ProxyVarianceView {
        var code: String
        var label: String
        var active: String
        var channel: String
        var locale: String
        var diagnosisCodeText: String
        var payerText: String
        var revision: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, active: String, channel: String, locale: String, diagnosisCodeText: String, payerText: String, revision: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.active = active
            self.channel = channel
            self.locale = locale
            self.diagnosisCodeText = diagnosisCodeText
            self.payerText = payerText
            self.revision = revision
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toProxyVarianceView(_ item: ProxyVariance) -> ProxyVarianceView {
        return ProxyVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            active: "\(item.active)",
            channel: item.channel,
            locale: item.locale,
            diagnosisCodeText: item.diagnosisCode,
            payerText: item.payer,
            revision: String(item.revision),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyVarianceViews(_ items: [ProxyVariance]) -> [ProxyVarianceView] {
        var views: [ProxyVarianceView] = []
        for item in items {
            views.append(toProxyVarianceView(item))
        }
        return views
    }

    static func sumProxyVarianceView(_ view: ProxyVarianceView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRevision) + parsedScore
    }
}
