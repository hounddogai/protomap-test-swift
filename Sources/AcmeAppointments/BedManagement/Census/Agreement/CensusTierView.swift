import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census tier.
    final class CensusTierView {
        var code: String
        var nameText: String
        var label: String
        var durationMinutesText: String
        var expiresAt: String
        var allergy: String
        var windowDays: String
        var pinned: String
        var statusLabel: String

        init(code: String, nameText: String, label: String, durationMinutesText: String, expiresAt: String, allergy: String, windowDays: String, pinned: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.label = label
            self.durationMinutesText = durationMinutesText
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.windowDays = windowDays
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toCensusTierView(_ item: CensusTier) -> CensusTierView {
        return CensusTierView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            label: item.label,
            durationMinutesText: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            windowDays: String(item.windowDays),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusTierViews(_ items: [CensusTier]) -> [CensusTierView] {
        var views: [CensusTierView] = []
        for item in items {
            views.append(toCensusTierView(item))
        }
        return views
    }

    static func sumCensusTierView(_ view: CensusTierView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedExpiresAt) + Double(parsedWindowDays)
    }
}
