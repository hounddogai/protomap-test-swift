import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive formulary milestone.
    final class AdaptiveFormularyMilestoneView {
        var code: String
        var title: String
        var segment: String
        var startsAt: String
        var margin: String
        var channelText: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, segment: String, startsAt: String, margin: String, channelText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.startsAt = startsAt
            self.margin = margin
            self.channelText = channelText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFormularyMilestoneView(_ item: AdaptiveFormularyMilestone) -> AdaptiveFormularyMilestoneView {
        return AdaptiveFormularyMilestoneView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            startsAt: String(item.startsAt),
            margin: String(format: "%.2f", item.margin),
            channelText: item.channel,
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFormularyMilestoneViews(_ items: [AdaptiveFormularyMilestone]) -> [AdaptiveFormularyMilestoneView] {
        var views: [AdaptiveFormularyMilestoneView] = []
        for item in items {
            views.append(toAdaptiveFormularyMilestoneView(item))
        }
        return views
    }

    static func sumAdaptiveFormularyMilestoneView(_ view: AdaptiveFormularyMilestoneView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedStartsAt) + parsedMargin
    }
}
