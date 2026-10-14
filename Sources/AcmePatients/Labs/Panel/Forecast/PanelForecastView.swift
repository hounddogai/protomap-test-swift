import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel forecast.
    final class PanelForecastView {
        var codeText: String
        var label: String
        var attempts: String
        var threshold: String
        var specialtyText: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, attempts: String, threshold: String, specialtyText: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.attempts = attempts
            self.threshold = threshold
            self.specialtyText = specialtyText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPanelForecastView(_ item: PanelForecast) -> PanelForecastView {
        return PanelForecastView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            attempts: String(item.attempts),
            threshold: String(format: "%.2f", item.threshold),
            specialtyText: item.specialty,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelForecastViews(_ items: [PanelForecast]) -> [PanelForecastView] {
        var views: [PanelForecastView] = []
        for item in items {
            views.append(toPanelForecastView(item))
        }
        return views
    }

    static func sumPanelForecastView(_ view: PanelForecastView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAttempts) + parsedThreshold + Double(parsedVisitMinutes)
    }
}
