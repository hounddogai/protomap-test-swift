import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy interaction segment.
    final class LegacyInteractionSegmentView {
        var codeText: String
        var label: String
        var locale: String
        var active: String
        var country: String
        var limit: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, locale: String, active: String, country: String, limit: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.locale = locale
            self.active = active
            self.country = country
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInteractionSegmentView(_ item: LegacyInteractionSegment) -> LegacyInteractionSegmentView {
        return LegacyInteractionSegmentView(
            codeText: item.code,
            label: item.label,
            locale: item.locale,
            active: "\(item.active)",
            country: item.country,
            limit: String(item.limit),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInteractionSegmentViews(_ items: [LegacyInteractionSegment]) -> [LegacyInteractionSegmentView] {
        var views: [LegacyInteractionSegmentView] = []
        for item in items {
            views.append(toLegacyInteractionSegmentView(item))
        }
        return views
    }

    static func sumLegacyInteractionSegmentView(_ view: LegacyInteractionSegmentView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedLimit) + Double(parsedDurationMinutes)
    }
}
