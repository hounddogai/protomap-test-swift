import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal referral mapping.
    final class SeasonalReferralMappingView {
        var code: String
        var label: String
        var sourceText: String
        var priority: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, label: String, sourceText: String, priority: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sourceText = sourceText
            self.priority = priority
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReferralMappingView(_ item: SeasonalReferralMapping) -> SeasonalReferralMappingView {
        return SeasonalReferralMappingView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            sourceText: item.source,
            priority: String(item.priority),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReferralMappingViews(_ items: [SeasonalReferralMapping]) -> [SeasonalReferralMappingView] {
        var views: [SeasonalReferralMappingView] = []
        for item in items {
            views.append(toSeasonalReferralMappingView(item))
        }
        return views
    }

    static func sumSeasonalReferralMappingView(_ view: SeasonalReferralMappingView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
