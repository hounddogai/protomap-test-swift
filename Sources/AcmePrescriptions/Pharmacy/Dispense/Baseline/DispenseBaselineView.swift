import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense baseline.
    final class DispenseBaselineView {
        var code: String
        var title: String
        var regionText: String
        var graceDays: String
        var channel: String
        var ratio: String
        var endsAtText: String
        var reviewer: String
        var acuityText: String
        var statusLabel: String

        init(code: String, title: String, regionText: String, graceDays: String, channel: String, ratio: String, endsAtText: String, reviewer: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.regionText = regionText
            self.graceDays = graceDays
            self.channel = channel
            self.ratio = ratio
            self.endsAtText = endsAtText
            self.reviewer = reviewer
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseBaselineView(_ item: DispenseBaseline) -> DispenseBaselineView {
        return DispenseBaselineView(
            code: item.code,
            title: item.title,
            regionText: Kit.Text.truncate(item.region, limit: 80),
            graceDays: String(item.graceDays),
            channel: item.channel,
            ratio: String(format: "%.2f", item.ratio),
            endsAtText: String(item.endsAt),
            reviewer: item.reviewer,
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseBaselineViews(_ items: [DispenseBaseline]) -> [DispenseBaselineView] {
        var views: [DispenseBaselineView] = []
        for item in items {
            views.append(toDispenseBaselineView(item))
        }
        return views
    }

    static func sumDispenseBaselineView(_ view: DispenseBaselineView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedGraceDays) + parsedRatio + Double(parsedEndsAt)
    }
}
