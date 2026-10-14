import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession forecast.
    final class AccessionForecastView {
        var codeText: String
        var title: String
        var ward: String
        var discount: String
        var locale: String
        var facility: String
        var createdAt: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, title: String, ward: String, discount: String, locale: String, facility: String, createdAt: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ward = ward
            self.discount = discount
            self.locale = locale
            self.facility = facility
            self.createdAt = createdAt
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionForecastView(_ item: AccessionForecast) -> AccessionForecastView {
        return AccessionForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            discount: String(format: "%.2f", item.discount),
            locale: item.locale,
            facility: item.facility,
            createdAt: String(item.createdAt),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionForecastViews(_ items: [AccessionForecast]) -> [AccessionForecastView] {
        var views: [AccessionForecastView] = []
        for item in items {
            views.append(toAccessionForecastView(item))
        }
        return views
    }

    static func sumAccessionForecastView(_ view: AccessionForecastView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedCreatedAt)
    }
}
