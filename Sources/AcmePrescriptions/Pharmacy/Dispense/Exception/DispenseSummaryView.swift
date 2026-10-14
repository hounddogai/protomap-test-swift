import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense summary.
    final class DispenseSummaryView {
        var code: String
        var titleText: String
        var regionText: String
        var visitMinutes: String
        var ownerID: String
        var weight: String
        var rate: String
        var ratio: String
        var retries: String
        var channelText: String
        var statusLabel: String

        init(code: String, titleText: String, regionText: String, visitMinutes: String, ownerID: String, weight: String, rate: String, ratio: String, retries: String, channelText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.regionText = regionText
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
            self.weight = weight
            self.rate = rate
            self.ratio = ratio
            self.retries = retries
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseSummaryView(_ item: DispenseSummary) -> DispenseSummaryView {
        return DispenseSummaryView(
            code: item.code,
            titleText: item.title,
            regionText: Kit.Text.truncate(item.region, limit: 80),
            visitMinutes: String(item.visitMinutes),
            ownerID: item.ownerID,
            weight: String(format: "%.2f", item.weight),
            rate: String(format: "%.2f", item.rate),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseSummaryViews(_ items: [DispenseSummary]) -> [DispenseSummaryView] {
        var views: [DispenseSummaryView] = []
        for item in items {
            views.append(toDispenseSummaryView(item))
        }
        return views
    }

    static func sumDispenseSummaryView(_ view: DispenseSummaryView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVisitMinutes) + parsedWeight + parsedRate
    }
}
