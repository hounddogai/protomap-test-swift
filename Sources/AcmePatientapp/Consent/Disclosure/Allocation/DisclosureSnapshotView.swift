import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure snapshot.
    final class DisclosureSnapshotView {
        var code: String
        var title: String
        var timezoneText: String
        var discount: String
        var reviewerText: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, timezoneText: String, discount: String, reviewerText: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.timezoneText = timezoneText
            self.discount = discount
            self.reviewerText = reviewerText
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureSnapshotView(_ item: DisclosureSnapshot) -> DisclosureSnapshotView {
        return DisclosureSnapshotView(
            code: item.code,
            title: item.title,
            timezoneText: item.timezone,
            discount: String(format: "%.2f", item.discount),
            reviewerText: item.reviewer,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureSnapshotViews(_ items: [DisclosureSnapshot]) -> [DisclosureSnapshotView] {
        var views: [DisclosureSnapshotView] = []
        for item in items {
            views.append(toDisclosureSnapshotView(item))
        }
        return views
    }

    static func sumDisclosureSnapshotView(_ view: DisclosureSnapshotView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
