import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered charge variance.
    final class TieredChargeVarianceView {
        var code: String
        var title: String
        var startsAtText: String
        var attemptsText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, startsAtText: String, attemptsText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.startsAtText = startsAtText
            self.attemptsText = attemptsText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredChargeVarianceView(_ item: TieredChargeVariance) -> TieredChargeVarianceView {
        return TieredChargeVarianceView(
            code: item.code,
            title: item.title,
            startsAtText: String(item.startsAt),
            attemptsText: String(item.attempts),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredChargeVarianceViews(_ items: [TieredChargeVariance]) -> [TieredChargeVarianceView] {
        var views: [TieredChargeVarianceView] = []
        for item in items {
            views.append(toTieredChargeVarianceView(item))
        }
        return views
    }

    static func sumTieredChargeVarianceView(_ view: TieredChargeVarianceView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAttempts)
    }
}
