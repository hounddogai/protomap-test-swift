import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback worklist agreement.
    final class FallbackWorklistAgreementView {
        var code: String
        var title: String
        var endsAt: String
        var scoreText: String
        var timezone: String
        var minimumText: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, scoreText: String, timezone: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.scoreText = scoreText
            self.timezone = timezone
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackWorklistAgreementView(_ item: FallbackWorklistAgreement) -> FallbackWorklistAgreementView {
        return FallbackWorklistAgreementView(
            code: item.code,
            title: item.title,
            endsAt: String(item.endsAt),
            scoreText: String(format: "%.2f", item.score),
            timezone: item.timezone,
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackWorklistAgreementViews(_ items: [FallbackWorklistAgreement]) -> [FallbackWorklistAgreementView] {
        var views: [FallbackWorklistAgreementView] = []
        for item in items {
            views.append(toFallbackWorklistAgreementView(item))
        }
        return views
    }

    static func sumFallbackWorklistAgreementView(_ view: FallbackWorklistAgreementView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedEndsAt) + parsedScore + parsedMinimum
    }
}
