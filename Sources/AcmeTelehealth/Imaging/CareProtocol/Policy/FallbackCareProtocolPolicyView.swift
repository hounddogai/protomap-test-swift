import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback care protocol policy.
    final class FallbackCareProtocolPolicyView {
        var code: String
        var title: String
        var payerText: String
        var specialty: String
        var threshold: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, title: String, payerText: String, specialty: String, threshold: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payerText = payerText
            self.specialty = specialty
            self.threshold = threshold
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolPolicyView(_ item: FallbackCareProtocolPolicy) -> FallbackCareProtocolPolicyView {
        return FallbackCareProtocolPolicyView(
            code: item.code,
            title: item.title,
            payerText: item.payer,
            specialty: item.specialty,
            threshold: String(format: "%.2f", item.threshold),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolPolicyViews(_ items: [FallbackCareProtocolPolicy]) -> [FallbackCareProtocolPolicyView] {
        var views: [FallbackCareProtocolPolicyView] = []
        for item in items {
            views.append(toFallbackCareProtocolPolicyView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolPolicyView(_ view: FallbackCareProtocolPolicyView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays)
    }
}
