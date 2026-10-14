import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap window.
    final class CareGapWindowView {
        var code: String
        var nameText: String
        var timezone: String
        var windowDays: String
        var active: String
        var ownerIDText: String
        var startsAt: String
        var threshold: String
        var graceDays: String
        var statusLabel: String

        init(code: String, nameText: String, timezone: String, windowDays: String, active: String, ownerIDText: String, startsAt: String, threshold: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.timezone = timezone
            self.windowDays = windowDays
            self.active = active
            self.ownerIDText = ownerIDText
            self.startsAt = startsAt
            self.threshold = threshold
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapWindowView(_ item: CareGapWindow) -> CareGapWindowView {
        return CareGapWindowView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            timezone: item.timezone,
            windowDays: String(item.windowDays),
            active: "\(item.active)",
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 40),
            startsAt: String(item.startsAt),
            threshold: String(format: "%.2f", item.threshold),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapWindowViews(_ items: [CareGapWindow]) -> [CareGapWindowView] {
        var views: [CareGapWindowView] = []
        for item in items {
            views.append(toCareGapWindowView(item))
        }
        return views
    }

    static func sumCareGapWindowView(_ view: CareGapWindowView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedStartsAt) + parsedThreshold
    }
}
