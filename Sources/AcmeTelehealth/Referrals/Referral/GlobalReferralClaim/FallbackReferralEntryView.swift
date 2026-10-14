import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback referral entry.
    final class FallbackReferralEntryView {
        var codeText: String
        var title: String
        var wardText: String
        var sequence: String
        var graceDays: String
        var floorValueText: String
        var phoneText: String
        var region: String
        var statusLabel: String

        init(codeText: String, title: String, wardText: String, sequence: String, graceDays: String, floorValueText: String, phoneText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.wardText = wardText
            self.sequence = sequence
            self.graceDays = graceDays
            self.floorValueText = floorValueText
            self.phoneText = phoneText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackReferralEntryView(_ item: FallbackReferralEntry) -> FallbackReferralEntryView {
        return FallbackReferralEntryView(
            codeText: item.code,
            title: item.title,
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            sequence: String(item.sequence),
            graceDays: String(item.graceDays),
            floorValueText: String(format: "%.2f", item.floorValue),
            phoneText: item.phone,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackReferralEntryViews(_ items: [FallbackReferralEntry]) -> [FallbackReferralEntryView] {
        var views: [FallbackReferralEntryView] = []
        for item in items {
            views.append(toFallbackReferralEntryView(item))
        }
        return views
    }

    static func sumFallbackReferralEntryView(_ view: FallbackReferralEntryView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedSequence) + Double(parsedGraceDays) + parsedFloorValue
    }
}
