import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback float pool schedule.
    final class FallbackFloatPoolScheduleView {
        var codeText: String
        var title: String
        var payer: String
        var threshold: String
        var graceDaysText: String
        var revision: String
        var country: String
        var regionText: String
        var costText: String
        var statusLabel: String

        init(codeText: String, title: String, payer: String, threshold: String, graceDaysText: String, revision: String, country: String, regionText: String, costText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.payer = payer
            self.threshold = threshold
            self.graceDaysText = graceDaysText
            self.revision = revision
            self.country = country
            self.regionText = regionText
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackFloatPoolScheduleView(_ item: FallbackFloatPoolSchedule) -> FallbackFloatPoolScheduleView {
        return FallbackFloatPoolScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            graceDaysText: String(item.graceDays),
            revision: String(item.revision),
            country: item.country,
            regionText: item.region,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackFloatPoolScheduleViews(_ items: [FallbackFloatPoolSchedule]) -> [FallbackFloatPoolScheduleView] {
        var views: [FallbackFloatPoolScheduleView] = []
        for item in items {
            views.append(toFallbackFloatPoolScheduleView(item))
        }
        return views
    }

    static func sumFallbackFloatPoolScheduleView(_ view: FallbackFloatPoolScheduleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + Double(parsedRevision)
    }
}
