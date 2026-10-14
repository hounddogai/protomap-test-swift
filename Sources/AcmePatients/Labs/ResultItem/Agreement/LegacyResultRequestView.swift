import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy result request.
    final class LegacyResultRequestView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var expiresAtText: String
        var allergyText: String
        var ceilingText: String
        var cost: String
        var active: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, expiresAtText: String, allergyText: String, ceilingText: String, cost: String, active: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.expiresAtText = expiresAtText
            self.allergyText = allergyText
            self.ceilingText = ceilingText
            self.cost = cost
            self.active = active
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyResultRequestView(_ item: LegacyResultRequest) -> LegacyResultRequestView {
        return LegacyResultRequestView(
            codeText: item.code,
            title: item.title,
            durationMinutesText: String(item.durationMinutes),
            expiresAtText: String(item.expiresAt),
            allergyText: item.allergy,
            ceilingText: String(format: "%.2f", item.ceiling),
            cost: String(format: "%.2f", item.cost),
            active: "\(item.active)",
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyResultRequestViews(_ items: [LegacyResultRequest]) -> [LegacyResultRequestView] {
        var views: [LegacyResultRequestView] = []
        for item in items {
            views.append(toLegacyResultRequestView(item))
        }
        return views
    }

    static func sumLegacyResultRequestView(_ view: LegacyResultRequestView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedExpiresAt) + parsedCeiling
    }
}
