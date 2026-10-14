import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered remittance budget.
    final class TieredRemittanceBudgetView {
        var code: String
        var nameText: String
        var ratio: String
        var durationMinutesText: String
        var phoneText: String
        var ward: String
        var timezone: String
        var maximumText: String
        var versionText: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, ratio: String, durationMinutesText: String, phoneText: String, ward: String, timezone: String, maximumText: String, versionText: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ratio = ratio
            self.durationMinutesText = durationMinutesText
            self.phoneText = phoneText
            self.ward = ward
            self.timezone = timezone
            self.maximumText = maximumText
            self.versionText = versionText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRemittanceBudgetView(_ item: TieredRemittanceBudget) -> TieredRemittanceBudgetView {
        return TieredRemittanceBudgetView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            durationMinutesText: String(item.durationMinutes),
            phoneText: item.phone,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            timezone: item.timezone,
            maximumText: String(format: "%.2f", item.maximum),
            versionText: String(item.version),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRemittanceBudgetViews(_ items: [TieredRemittanceBudget]) -> [TieredRemittanceBudgetView] {
        var views: [TieredRemittanceBudgetView] = []
        for item in items {
            views.append(toTieredRemittanceBudgetView(item))
        }
        return views
    }

    static func sumTieredRemittanceBudgetView(_ view: TieredRemittanceBudgetView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + Double(parsedDurationMinutes) + parsedMaximum
    }
}
