import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending cleaning window.
    final class PendingCleaningWindowView {
        var code: String
        var label: String
        var minimumText: String
        var active: String
        var reviewer: String
        var ratio: String
        var durationMinutes: String
        var expiresAt: String
        var maximumText: String
        var statusLabel: String

        init(code: String, label: String, minimumText: String, active: String, reviewer: String, ratio: String, durationMinutes: String, expiresAt: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimumText = minimumText
            self.active = active
            self.reviewer = reviewer
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCleaningWindowView(_ item: PendingCleaningWindow) -> PendingCleaningWindowView {
        return PendingCleaningWindowView(
            code: item.code,
            label: item.label,
            minimumText: String(format: "%.2f", item.minimum),
            active: "\(item.active)",
            reviewer: item.reviewer,
            ratio: String(format: "%.2f", item.ratio),
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCleaningWindowViews(_ items: [PendingCleaningWindow]) -> [PendingCleaningWindowView] {
        var views: [PendingCleaningWindowView] = []
        for item in items {
            views.append(toPendingCleaningWindowView(item))
        }
        return views
    }

    static func sumPendingCleaningWindowView(_ view: PendingCleaningWindowView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + parsedRatio + Double(parsedDurationMinutes)
    }
}
