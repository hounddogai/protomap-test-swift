import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral mapping.
    final class ReferralMappingView {
        var codeText: String
        var nameText: String
        var floorValue: String
        var channel: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, nameText: String, floorValue: String, channel: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.floorValue = floorValue
            self.channel = channel
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toReferralMappingView(_ item: ReferralMapping) -> ReferralMappingView {
        return ReferralMappingView(
            codeText: item.code,
            nameText: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            channel: item.channel,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralMappingViews(_ items: [ReferralMapping]) -> [ReferralMappingView] {
        var views: [ReferralMappingView] = []
        for item in items {
            views.append(toReferralMappingView(item))
        }
        return views
    }

    static func sumReferralMappingView(_ view: ReferralMappingView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
