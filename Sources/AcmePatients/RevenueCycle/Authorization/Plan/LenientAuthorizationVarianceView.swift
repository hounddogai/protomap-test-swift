import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient authorization variance.
    final class LenientAuthorizationVarianceView {
        var code: String
        var title: String
        var rate: String
        var attempts: String
        var ceilingText: String
        var retriesText: String
        var phoneText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, rate: String, attempts: String, ceilingText: String, retriesText: String, phoneText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rate = rate
            self.attempts = attempts
            self.ceilingText = ceilingText
            self.retriesText = retriesText
            self.phoneText = phoneText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAuthorizationVarianceView(_ item: LenientAuthorizationVariance) -> LenientAuthorizationVarianceView {
        return LenientAuthorizationVarianceView(
            code: item.code,
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            attempts: String(item.attempts),
            ceilingText: String(format: "%.2f", item.ceiling),
            retriesText: String(item.retries),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAuthorizationVarianceViews(_ items: [LenientAuthorizationVariance]) -> [LenientAuthorizationVarianceView] {
        var views: [LenientAuthorizationVarianceView] = []
        for item in items {
            views.append(toLenientAuthorizationVarianceView(item))
        }
        return views
    }

    static func sumLenientAuthorizationVarianceView(_ view: LenientAuthorizationVarianceView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedRate + Double(parsedAttempts) + parsedCeiling
    }
}
