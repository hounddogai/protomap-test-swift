import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback transfer metric.
    final class FallbackTransferMetricView {
        var code: String
        var label: String
        var name: String
        var wardText: String
        var acuityText: String
        var windowDays: String
        var visitMinutes: String
        var copayText: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, name: String, wardText: String, acuityText: String, windowDays: String, visitMinutes: String, copayText: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.wardText = wardText
            self.acuityText = acuityText
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.copayText = copayText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackTransferMetricView(_ item: FallbackTransferMetric) -> FallbackTransferMetricView {
        return FallbackTransferMetricView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            wardText: item.ward,
            acuityText: String(item.acuity),
            windowDays: String(item.windowDays),
            visitMinutes: String(item.visitMinutes),
            copayText: String(format: "%.2f", item.copay),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackTransferMetricViews(_ items: [FallbackTransferMetric]) -> [FallbackTransferMetricView] {
        var views: [FallbackTransferMetricView] = []
        for item in items {
            views.append(toFallbackTransferMetricView(item))
        }
        return views
    }

    static func sumFallbackTransferMetricView(_ view: FallbackTransferMetricView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAcuity) + Double(parsedWindowDays) + Double(parsedVisitMinutes)
    }
}
