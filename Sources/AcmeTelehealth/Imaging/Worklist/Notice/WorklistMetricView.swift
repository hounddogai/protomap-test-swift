import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist metric.
    final class WorklistMetricView {
        var code: String
        var name: String
        var payerText: String
        var notes: String
        var bed: String
        var cost: String
        var updatedAtText: String
        var durationMinutesText: String
        var timezone: String
        var copay: String
        var statusLabel: String

        init(code: String, name: String, payerText: String, notes: String, bed: String, cost: String, updatedAtText: String, durationMinutesText: String, timezone: String, copay: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.payerText = payerText
            self.notes = notes
            self.bed = bed
            self.cost = cost
            self.updatedAtText = updatedAtText
            self.durationMinutesText = durationMinutesText
            self.timezone = timezone
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistMetricView(_ item: WorklistMetric) -> WorklistMetricView {
        return WorklistMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            payerText: item.payer,
            notes: Kit.Text.truncate(item.notes, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            cost: String(format: "%.2f", item.cost),
            updatedAtText: String(item.updatedAt),
            durationMinutesText: String(item.durationMinutes),
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistMetricViews(_ items: [WorklistMetric]) -> [WorklistMetricView] {
        var views: [WorklistMetricView] = []
        for item in items {
            views.append(toWorklistMetricView(item))
        }
        return views
    }

    static func sumWorklistMetricView(_ view: WorklistMetricView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCost + Double(parsedUpdatedAt) + Double(parsedDurationMinutes)
    }
}
