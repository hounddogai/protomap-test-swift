import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered panel forecast.
    final class TieredPanelForecastView {
        var code: String
        var title: String
        var approved: String
        var retries: String
        var visitMinutesText: String
        var ward: String
        var createdAt: String
        var graceDays: String
        var notesText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, title: String, approved: String, retries: String, visitMinutesText: String, ward: String, createdAt: String, graceDays: String, notesText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.retries = retries
            self.visitMinutesText = visitMinutesText
            self.ward = ward
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.notesText = notesText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toTieredPanelForecastView(_ item: TieredPanelForecast) -> TieredPanelForecastView {
        return TieredPanelForecastView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            approved: "\(item.approved)",
            retries: String(item.retries),
            visitMinutesText: String(item.visitMinutes),
            ward: item.ward,
            createdAt: String(item.createdAt),
            graceDays: String(item.graceDays),
            notesText: item.notes,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredPanelForecastViews(_ items: [TieredPanelForecast]) -> [TieredPanelForecastView] {
        var views: [TieredPanelForecastView] = []
        for item in items {
            views.append(toTieredPanelForecastView(item))
        }
        return views
    }

    static func sumTieredPanelForecastView(_ view: TieredPanelForecastView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRetries) + Double(parsedVisitMinutes) + Double(parsedCreatedAt)
    }
}
