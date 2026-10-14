import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy referral entry.
    final class LegacyReferralEntryView {
        var code: String
        var title: String
        var name: String
        var marginText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, name: String, marginText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.name = name
            self.marginText = marginText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyReferralEntryView(_ item: LegacyReferralEntry) -> LegacyReferralEntryView {
        return LegacyReferralEntryView(
            code: item.code,
            title: item.title,
            name: item.name,
            marginText: String(format: "%.2f", item.margin),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyReferralEntryViews(_ items: [LegacyReferralEntry]) -> [LegacyReferralEntryView] {
        var views: [LegacyReferralEntryView] = []
        for item in items {
            views.append(toLegacyReferralEntryView(item))
        }
        return views
    }

    static func sumLegacyReferralEntryView(_ view: LegacyReferralEntryView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMargin + parsedFloorValue
    }
}
