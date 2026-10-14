import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped specimen cycle.
    final class CappedSpecimenCycleView {
        var code: String
        var title: String
        var windowDays: String
        var limit: String
        var segment: String
        var copayText: String
        var createdAt: String
        var unitText: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, limit: String, segment: String, copayText: String, createdAt: String, unitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.limit = limit
            self.segment = segment
            self.copayText = copayText
            self.createdAt = createdAt
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSpecimenCycleView(_ item: CappedSpecimenCycle) -> CappedSpecimenCycleView {
        return CappedSpecimenCycleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            windowDays: String(item.windowDays),
            limit: String(item.limit),
            segment: item.segment,
            copayText: String(format: "%.2f", item.copay),
            createdAt: String(item.createdAt),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSpecimenCycleViews(_ items: [CappedSpecimenCycle]) -> [CappedSpecimenCycleView] {
        var views: [CappedSpecimenCycleView] = []
        for item in items {
            views.append(toCappedSpecimenCycleView(item))
        }
        return views
    }

    static func sumCappedSpecimenCycleView(_ view: CappedSpecimenCycleView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedLimit) + parsedCopay
    }
}
