import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default float pool notice.
    final class DefaultFloatPoolNoticeView {
        var code: String
        var labelText: String
        var ratio: String
        var graceDays: String
        var summaryText: String
        var floorValue: String
        var rate: String
        var thresholdText: String
        var startsAt: String
        var statusLabel: String

        init(code: String, labelText: String, ratio: String, graceDays: String, summaryText: String, floorValue: String, rate: String, thresholdText: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ratio = ratio
            self.graceDays = graceDays
            self.summaryText = summaryText
            self.floorValue = floorValue
            self.rate = rate
            self.thresholdText = thresholdText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFloatPoolNoticeView(_ item: DefaultFloatPoolNotice) -> DefaultFloatPoolNoticeView {
        return DefaultFloatPoolNoticeView(
            code: item.code,
            labelText: item.label,
            ratio: String(format: "%.2f", item.ratio),
            graceDays: String(item.graceDays),
            summaryText: item.summary,
            floorValue: String(format: "%.2f", item.floorValue),
            rate: String(format: "%.2f", item.rate),
            thresholdText: String(format: "%.2f", item.threshold),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFloatPoolNoticeViews(_ items: [DefaultFloatPoolNotice]) -> [DefaultFloatPoolNoticeView] {
        var views: [DefaultFloatPoolNoticeView] = []
        for item in items {
            views.append(toDefaultFloatPoolNoticeView(item))
        }
        return views
    }

    static func sumDefaultFloatPoolNoticeView(_ view: DefaultFloatPoolNoticeView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedRatio + Double(parsedGraceDays) + parsedFloorValue
    }
}
