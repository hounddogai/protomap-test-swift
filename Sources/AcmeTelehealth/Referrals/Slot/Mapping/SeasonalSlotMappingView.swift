import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal slot mapping.
    final class SeasonalSlotMappingView {
        var code: String
        var name: String
        var refills: String
        var currencyText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, refills: String, currencyText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.refills = refills
            self.currencyText = currencyText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSlotMappingView(_ item: SeasonalSlotMapping) -> SeasonalSlotMappingView {
        return SeasonalSlotMappingView(
            code: item.code,
            name: item.name,
            refills: String(item.refills),
            currencyText: item.currency,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSlotMappingViews(_ items: [SeasonalSlotMapping]) -> [SeasonalSlotMappingView] {
        var views: [SeasonalSlotMappingView] = []
        for item in items {
            views.append(toSeasonalSlotMappingView(item))
        }
        return views
    }

    static func sumSeasonalSlotMappingView(_ view: SeasonalSlotMappingView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRefills) + Double(parsedEndsAt)
    }
}
