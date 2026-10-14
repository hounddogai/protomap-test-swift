import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol forecast.
    final class CareProtocolForecastView {
        var codeText: String
        var title: String
        var labelText: String
        var bedText: String
        var createdAt: String
        var facility: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, title: String, labelText: String, bedText: String, createdAt: String, facility: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.labelText = labelText
            self.bedText = bedText
            self.createdAt = createdAt
            self.facility = facility
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolForecastView(_ item: CareProtocolForecast) -> CareProtocolForecastView {
        return CareProtocolForecastView(
            codeText: item.code,
            title: item.title,
            labelText: item.label,
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            createdAt: String(item.createdAt),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolForecastViews(_ items: [CareProtocolForecast]) -> [CareProtocolForecastView] {
        var views: [CareProtocolForecastView] = []
        for item in items {
            views.append(toCareProtocolForecastView(item))
        }
        return views
    }

    static func sumCareProtocolForecastView(_ view: CareProtocolForecastView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + parsedDosageMg
    }
}
