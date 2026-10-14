import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime forecast.
    final class OvertimeForecastView {
        var codeText: String
        var label: String
        var visible: String
        var wardText: String
        var refills: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, visible: String, wardText: String, refills: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.visible = visible
            self.wardText = wardText
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeForecastView(_ item: OvertimeForecast) -> OvertimeForecastView {
        return OvertimeForecastView(
            codeText: item.code,
            label: item.label,
            visible: "\(item.visible)",
            wardText: item.ward,
            refills: String(item.refills),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeForecastViews(_ items: [OvertimeForecast]) -> [OvertimeForecastView] {
        var views: [OvertimeForecastView] = []
        for item in items {
            views.append(toOvertimeForecastView(item))
        }
        return views
    }

    static func sumOvertimeForecastView(_ view: OvertimeForecastView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRefills) + Double(parsedVisitMinutes)
    }
}
