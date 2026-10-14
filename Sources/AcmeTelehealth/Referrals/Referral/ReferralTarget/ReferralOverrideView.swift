import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral override.
    final class ReferralOverrideView {
        var code: String
        var label: String
        var encounterID: String
        var expiresAt: String
        var timezoneText: String
        var bed: String
        var windowDays: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, expiresAt: String, timezoneText: String, bed: String, windowDays: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.expiresAt = expiresAt
            self.timezoneText = timezoneText
            self.bed = bed
            self.windowDays = windowDays
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toReferralOverrideView(_ item: ReferralOverride) -> ReferralOverrideView {
        return ReferralOverrideView(
            code: item.code,
            label: item.label,
            encounterID: item.encounterID,
            expiresAt: String(item.expiresAt),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            windowDays: String(item.windowDays),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralOverrideViews(_ items: [ReferralOverride]) -> [ReferralOverrideView] {
        var views: [ReferralOverrideView] = []
        for item in items {
            views.append(toReferralOverrideView(item))
        }
        return views
    }

    static func sumReferralOverrideView(_ view: ReferralOverrideView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedWindowDays) + parsedFloorValue
    }
}
