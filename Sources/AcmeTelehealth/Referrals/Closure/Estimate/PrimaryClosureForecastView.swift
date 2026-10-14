import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary closure forecast.
    final class PrimaryClosureForecastView {
        var code: String
        var label: String
        var priority: String
        var phoneText: String
        var clinicianID: String
        var unitText: String
        var minimumText: String
        var statusLabel: String

        init(code: String, label: String, priority: String, phoneText: String, clinicianID: String, unitText: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.priority = priority
            self.phoneText = phoneText
            self.clinicianID = clinicianID
            self.unitText = unitText
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryClosureForecastView(_ item: PrimaryClosureForecast) -> PrimaryClosureForecastView {
        return PrimaryClosureForecastView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            priority: String(item.priority),
            phoneText: item.phone,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            unitText: item.unit,
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryClosureForecastViews(_ items: [PrimaryClosureForecast]) -> [PrimaryClosureForecastView] {
        var views: [PrimaryClosureForecastView] = []
        for item in items {
            views.append(toPrimaryClosureForecastView(item))
        }
        return views
    }

    static func sumPrimaryClosureForecastView(_ view: PrimaryClosureForecastView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedPriority) + parsedMinimum
    }
}
