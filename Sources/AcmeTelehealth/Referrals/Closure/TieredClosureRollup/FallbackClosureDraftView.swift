import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback closure draft.
    final class FallbackClosureDraftView {
        var code: String
        var label: String
        var timezoneText: String
        var reviewer: String
        var amount: String
        var channelText: String
        var endsAt: String
        var active: String
        var retriesText: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, reviewer: String, amount: String, channelText: String, endsAt: String, active: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.reviewer = reviewer
            self.amount = amount
            self.channelText = channelText
            self.endsAt = endsAt
            self.active = active
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackClosureDraftView(_ item: FallbackClosureDraft) -> FallbackClosureDraftView {
        return FallbackClosureDraftView(
            code: item.code,
            label: item.label,
            timezoneText: item.timezone,
            reviewer: item.reviewer,
            amount: String(format: "%.2f", item.amount),
            channelText: item.channel,
            endsAt: String(item.endsAt),
            active: "\(item.active)",
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackClosureDraftViews(_ items: [FallbackClosureDraft]) -> [FallbackClosureDraftView] {
        var views: [FallbackClosureDraftView] = []
        for item in items {
            views.append(toFallbackClosureDraftView(item))
        }
        return views
    }

    static func sumFallbackClosureDraftView(_ view: FallbackClosureDraftView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedAmount + Double(parsedEndsAt) + Double(parsedRetries)
    }
}
