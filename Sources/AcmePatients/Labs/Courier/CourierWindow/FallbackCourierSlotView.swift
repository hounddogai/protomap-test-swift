import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback courier slot.
    final class FallbackCourierSlotView {
        var code: String
        var name: String
        var summary: String
        var timezone: String
        var endsAt: String
        var reviewer: String
        var activeText: String
        var threshold: String
        var statusLabel: String

        init(code: String, name: String, summary: String, timezone: String, endsAt: String, reviewer: String, activeText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.summary = summary
            self.timezone = timezone
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.activeText = activeText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCourierSlotView(_ item: FallbackCourierSlot) -> FallbackCourierSlotView {
        return FallbackCourierSlotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            summary: item.summary,
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            endsAt: String(item.endsAt),
            reviewer: item.reviewer,
            activeText: "\(item.active)",
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCourierSlotViews(_ items: [FallbackCourierSlot]) -> [FallbackCourierSlotView] {
        var views: [FallbackCourierSlotView] = []
        for item in items {
            views.append(toFallbackCourierSlotView(item))
        }
        return views
    }

    static func sumFallbackCourierSlotView(_ view: FallbackCourierSlotView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedEndsAt) + parsedThreshold
    }
}
