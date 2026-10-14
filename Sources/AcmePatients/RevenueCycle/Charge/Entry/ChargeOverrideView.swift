import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge override.
    final class ChargeOverrideView {
        var code: String
        var name: String
        var diagnosisCode: String
        var rate: String
        var approved: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, rate: String, approved: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toChargeOverrideView(_ item: ChargeOverride) -> ChargeOverrideView {
        return ChargeOverrideView(
            code: item.code,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            rate: String(format: "%.2f", item.rate),
            approved: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeOverrideViews(_ items: [ChargeOverride]) -> [ChargeOverrideView] {
        var views: [ChargeOverrideView] = []
        for item in items {
            views.append(toChargeOverrideView(item))
        }
        return views
    }

    static func sumChargeOverrideView(_ view: ChargeOverrideView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedRate + Double(parsedDurationMinutes)
    }
}
