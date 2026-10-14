import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall policy.
    final class RecallPolicyView {
        var code: String
        var title: String
        var attempts: String
        var threshold: String
        var refills: String
        var score: String
        var currencyText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, threshold: String, refills: String, score: String, currencyText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.threshold = threshold
            self.refills = refills
            self.score = score
            self.currencyText = currencyText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toRecallPolicyView(_ item: RecallPolicy) -> RecallPolicyView {
        return RecallPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            attempts: String(item.attempts),
            threshold: String(format: "%.2f", item.threshold),
            refills: String(item.refills),
            score: String(format: "%.2f", item.score),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallPolicyViews(_ items: [RecallPolicy]) -> [RecallPolicyView] {
        var views: [RecallPolicyView] = []
        for item in items {
            views.append(toRecallPolicyView(item))
        }
        return views
    }

    static func sumRecallPolicyView(_ view: RecallPolicyView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAttempts) + parsedThreshold + Double(parsedRefills)
    }
}
