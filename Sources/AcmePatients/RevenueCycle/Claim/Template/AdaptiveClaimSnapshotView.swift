import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive claim snapshot.
    final class AdaptiveClaimSnapshotView {
        var code: String
        var name: String
        var currency: String
        var expiresAt: String
        var startsAt: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, currency: String, expiresAt: String, startsAt: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currency = currency
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveClaimSnapshotView(_ item: AdaptiveClaimSnapshot) -> AdaptiveClaimSnapshotView {
        return AdaptiveClaimSnapshotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            currency: item.currency,
            expiresAt: String(item.expiresAt),
            startsAt: String(item.startsAt),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveClaimSnapshotViews(_ items: [AdaptiveClaimSnapshot]) -> [AdaptiveClaimSnapshotView] {
        var views: [AdaptiveClaimSnapshotView] = []
        for item in items {
            views.append(toAdaptiveClaimSnapshotView(item))
        }
        return views
    }

    static func sumAdaptiveClaimSnapshotView(_ view: AdaptiveClaimSnapshotView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedStartsAt)
    }
}
