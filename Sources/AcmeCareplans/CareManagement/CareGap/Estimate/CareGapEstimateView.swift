import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap estimate.
    final class CareGapEstimateView {
        var code: String
        var labelText: String
        var unit: String
        var windowDays: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, labelText: String, unit: String, windowDays: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.unit = unit
            self.windowDays = windowDays
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapEstimateView(_ item: CareGapEstimate) -> CareGapEstimateView {
        return CareGapEstimateView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            windowDays: String(item.windowDays),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapEstimateViews(_ items: [CareGapEstimate]) -> [CareGapEstimateView] {
        var views: [CareGapEstimateView] = []
        for item in items {
            views.append(toCareGapEstimateView(item))
        }
        return views
    }

    static func sumCareGapEstimateView(_ view: CareGapEstimateView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedCreatedAt)
    }
}
