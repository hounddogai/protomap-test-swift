import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback network snapshot.
    final class FallbackNetworkSnapshotView {
        var code: String
        var titleText: String
        var allergy: String
        var discountText: String
        var ownerID: String
        var contactEmail: String
        var activeText: String
        var segmentText: String
        var summary: String
        var statusLabel: String

        init(code: String, titleText: String, allergy: String, discountText: String, ownerID: String, contactEmail: String, activeText: String, segmentText: String, summary: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.allergy = allergy
            self.discountText = discountText
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.activeText = activeText
            self.segmentText = segmentText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackNetworkSnapshotView(_ item: FallbackNetworkSnapshot) -> FallbackNetworkSnapshotView {
        return FallbackNetworkSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            allergy: item.allergy,
            discountText: String(format: "%.2f", item.discount),
            ownerID: item.ownerID,
            contactEmail: item.contactEmail,
            activeText: "\(item.active)",
            segmentText: item.segment,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackNetworkSnapshotViews(_ items: [FallbackNetworkSnapshot]) -> [FallbackNetworkSnapshotView] {
        var views: [FallbackNetworkSnapshotView] = []
        for item in items {
            views.append(toFallbackNetworkSnapshotView(item))
        }
        return views
    }

    static func sumFallbackNetworkSnapshotView(_ view: FallbackNetworkSnapshotView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
