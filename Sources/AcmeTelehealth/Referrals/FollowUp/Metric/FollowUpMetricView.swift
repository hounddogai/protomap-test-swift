import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up metric.
    final class FollowUpMetricView {
        var code: String
        var labelText: String
        var ratioText: String
        var bed: String
        var channelText: String
        var statusLabel: String

        init(code: String, labelText: String, ratioText: String, bed: String, channelText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ratioText = ratioText
            self.bed = bed
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpMetricView(_ item: FollowUpMetric) -> FollowUpMetricView {
        return FollowUpMetricView(
            code: item.code,
            labelText: item.label,
            ratioText: String(format: "%.2f", item.ratio),
            bed: item.bed,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpMetricViews(_ items: [FollowUpMetric]) -> [FollowUpMetricView] {
        var views: [FollowUpMetricView] = []
        for item in items {
            views.append(toFollowUpMetricView(item))
        }
        return views
    }

    static func sumFollowUpMetricView(_ view: FollowUpMetricView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
