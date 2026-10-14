import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional risk score summary.
    final class RegionalRiskScoreSummaryView {
        var code: String
        var title: String
        var capacity: String
        var floorValue: String
        var source: String
        var retriesText: String
        var channelText: String
        var country: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, floorValue: String, source: String, retriesText: String, channelText: String, country: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.floorValue = floorValue
            self.source = source
            self.retriesText = retriesText
            self.channelText = channelText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRiskScoreSummaryView(_ item: RegionalRiskScoreSummary) -> RegionalRiskScoreSummaryView {
        return RegionalRiskScoreSummaryView(
            code: item.code,
            title: item.title,
            capacity: String(item.capacity),
            floorValue: String(format: "%.2f", item.floorValue),
            source: Kit.Text.truncate(item.source, limit: 80),
            retriesText: String(item.retries),
            channelText: item.channel,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRiskScoreSummaryViews(_ items: [RegionalRiskScoreSummary]) -> [RegionalRiskScoreSummaryView] {
        var views: [RegionalRiskScoreSummaryView] = []
        for item in items {
            views.append(toRegionalRiskScoreSummaryView(item))
        }
        return views
    }

    static func sumRegionalRiskScoreSummaryView(_ view: RegionalRiskScoreSummaryView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCapacity) + parsedFloorValue + Double(parsedRetries)
    }
}
