import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered priority schedule.
    final class TieredPriorityScheduleView {
        var code: String
        var label: String
        var weight: String
        var revision: String
        var country: String
        var threshold: String
        var approved: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, weight: String, revision: String, country: String, threshold: String, approved: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.revision = revision
            self.country = country
            self.threshold = threshold
            self.approved = approved
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toTieredPriorityScheduleView(_ item: TieredPrioritySchedule) -> TieredPriorityScheduleView {
        return TieredPriorityScheduleView(
            code: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            revision: String(item.revision),
            country: item.country,
            threshold: String(format: "%.2f", item.threshold),
            approved: "\(item.approved)",
            summary: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredPriorityScheduleViews(_ items: [TieredPrioritySchedule]) -> [TieredPriorityScheduleView] {
        var views: [TieredPriorityScheduleView] = []
        for item in items {
            views.append(toTieredPriorityScheduleView(item))
        }
        return views
    }

    static func sumTieredPriorityScheduleView(_ view: TieredPriorityScheduleView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedWeight + Double(parsedRevision) + parsedThreshold
    }
}
