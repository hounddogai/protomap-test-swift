import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility forecast.
    final class EligibilityForecastView {
        var codeText: String
        var labelText: String
        var weight: String
        var patientRef: String
        var wardText: String
        var acuity: String
        var visibleText: String
        var statusLabel: String

        init(codeText: String, labelText: String, weight: String, patientRef: String, wardText: String, acuity: String, visibleText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.weight = weight
            self.patientRef = patientRef
            self.wardText = wardText
            self.acuity = acuity
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityForecastView(_ item: EligibilityForecast) -> EligibilityForecastView {
        return EligibilityForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            weight: String(format: "%.2f", item.weight),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            wardText: item.ward,
            acuity: String(item.acuity),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityForecastViews(_ items: [EligibilityForecast]) -> [EligibilityForecastView] {
        var views: [EligibilityForecastView] = []
        for item in items {
            views.append(toEligibilityForecastView(item))
        }
        return views
    }

    static func sumEligibilityForecastView(_ view: EligibilityForecastView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedWeight + Double(parsedAcuity)
    }
}
