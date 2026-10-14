import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled claim snapshot.
    final class ScheduledClaimSnapshotView {
        var code: String
        var name: String
        var activeText: String
        var limitText: String
        var contactEmail: String
        var segmentText: String
        var statusLabel: String

        init(code: String, name: String, activeText: String, limitText: String, contactEmail: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.activeText = activeText
            self.limitText = limitText
            self.contactEmail = contactEmail
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledClaimSnapshotView(_ item: ScheduledClaimSnapshot) -> ScheduledClaimSnapshotView {
        return ScheduledClaimSnapshotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            activeText: "\(item.active)",
            limitText: String(item.limit),
            contactEmail: item.contactEmail,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledClaimSnapshotViews(_ items: [ScheduledClaimSnapshot]) -> [ScheduledClaimSnapshotView] {
        var views: [ScheduledClaimSnapshotView] = []
        for item in items {
            views.append(toScheduledClaimSnapshotView(item))
        }
        return views
    }

    static func sumScheduledClaimSnapshotView(_ view: ScheduledClaimSnapshotView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
