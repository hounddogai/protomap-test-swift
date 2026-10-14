import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy interaction forecast.
    final class LegacyInteractionForecastView {
        var codeText: String
        var title: String
        var ward: String
        var facility: String
        var dosageMg: String
        var externalRef: String
        var clinicianID: String
        var segment: String
        var budget: String
        var summary: String
        var statusLabel: String

        init(codeText: String, title: String, ward: String, facility: String, dosageMg: String, externalRef: String, clinicianID: String, segment: String, budget: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ward = ward
            self.facility = facility
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.segment = segment
            self.budget = budget
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInteractionForecastView(_ item: LegacyInteractionForecast) -> LegacyInteractionForecastView {
        return LegacyInteractionForecastView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            ward: item.ward,
            facility: item.facility,
            dosageMg: String(format: "%.2f", item.dosageMg),
            externalRef: item.externalRef,
            clinicianID: item.clinicianID,
            segment: item.segment,
            budget: String(format: "%.2f", item.budget),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInteractionForecastViews(_ items: [LegacyInteractionForecast]) -> [LegacyInteractionForecastView] {
        var views: [LegacyInteractionForecastView] = []
        for item in items {
            views.append(toLegacyInteractionForecastView(item))
        }
        return views
    }

    static func sumLegacyInteractionForecastView(_ view: LegacyInteractionForecastView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedDosageMg + parsedBudget
    }
}
