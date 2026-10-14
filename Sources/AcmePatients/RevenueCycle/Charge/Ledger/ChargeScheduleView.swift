import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge schedule.
    final class ChargeScheduleView {
        var code: String
        var nameText: String
        var notes: String
        var segment: String
        var threshold: String
        var ceilingText: String
        var maximum: String
        var externalRef: String
        var description: String
        var statusLabel: String

        init(code: String, nameText: String, notes: String, segment: String, threshold: String, ceilingText: String, maximum: String, externalRef: String, description: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.notes = notes
            self.segment = segment
            self.threshold = threshold
            self.ceilingText = ceilingText
            self.maximum = maximum
            self.externalRef = externalRef
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toChargeScheduleView(_ item: ChargeSchedule) -> ChargeScheduleView {
        return ChargeScheduleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            notes: item.notes,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            ceilingText: String(format: "%.2f", item.ceiling),
            maximum: String(format: "%.2f", item.maximum),
            externalRef: item.externalRef,
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeScheduleViews(_ items: [ChargeSchedule]) -> [ChargeScheduleView] {
        var views: [ChargeScheduleView] = []
        for item in items {
            views.append(toChargeScheduleView(item))
        }
        return views
    }

    static func sumChargeScheduleView(_ view: ChargeScheduleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedThreshold + parsedCeiling + parsedMaximum
    }
}
