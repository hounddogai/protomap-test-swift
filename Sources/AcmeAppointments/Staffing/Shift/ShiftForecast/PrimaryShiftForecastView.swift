import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary shift forecast.
    final class PrimaryShiftForecastView {
        var code: String
        var label: String
        var procedureCode: String
        var createdAt: String
        var archivedText: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, createdAt: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.createdAt = createdAt
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryShiftForecastView(_ item: PrimaryShiftForecast) -> PrimaryShiftForecastView {
        return PrimaryShiftForecastView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            procedureCode: item.procedureCode,
            createdAt: String(item.createdAt),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryShiftForecastViews(_ items: [PrimaryShiftForecast]) -> [PrimaryShiftForecastView] {
        var views: [PrimaryShiftForecastView] = []
        for item in items {
            views.append(toPrimaryShiftForecastView(item))
        }
        return views
    }

    static func sumPrimaryShiftForecastView(_ view: PrimaryShiftForecastView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
