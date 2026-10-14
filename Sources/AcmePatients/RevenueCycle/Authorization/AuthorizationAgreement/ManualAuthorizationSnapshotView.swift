import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual authorization snapshot.
    final class ManualAuthorizationSnapshotView {
        var codeText: String
        var titleText: String
        var startsAtText: String
        var endsAtText: String
        var expiresAt: String
        var refills: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, titleText: String, startsAtText: String, endsAtText: String, expiresAt: String, refills: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.startsAtText = startsAtText
            self.endsAtText = endsAtText
            self.expiresAt = expiresAt
            self.refills = refills
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toManualAuthorizationSnapshotView(_ item: ManualAuthorizationSnapshot) -> ManualAuthorizationSnapshotView {
        return ManualAuthorizationSnapshotView(
            codeText: item.code,
            titleText: item.title,
            startsAtText: String(item.startsAt),
            endsAtText: String(item.endsAt),
            expiresAt: String(item.expiresAt),
            refills: String(item.refills),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAuthorizationSnapshotViews(_ items: [ManualAuthorizationSnapshot]) -> [ManualAuthorizationSnapshotView] {
        var views: [ManualAuthorizationSnapshotView] = []
        for item in items {
            views.append(toManualAuthorizationSnapshotView(item))
        }
        return views
    }

    static func sumManualAuthorizationSnapshotView(_ view: ManualAuthorizationSnapshotView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedEndsAt) + Double(parsedExpiresAt)
    }
}
