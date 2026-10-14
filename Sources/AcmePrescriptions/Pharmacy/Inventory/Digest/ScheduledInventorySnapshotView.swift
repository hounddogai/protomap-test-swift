import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled inventory snapshot.
    final class ScheduledInventorySnapshotView {
        var code: String
        var titleText: String
        var limitText: String
        var archived: String
        var visitMinutes: String
        var refills: String
        var statusLabel: String

        init(code: String, titleText: String, limitText: String, archived: String, visitMinutes: String, refills: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.limitText = limitText
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledInventorySnapshotView(_ item: ScheduledInventorySnapshot) -> ScheduledInventorySnapshotView {
        return ScheduledInventorySnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            limitText: String(item.limit),
            archived: "\(item.archived)",
            visitMinutes: String(item.visitMinutes),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledInventorySnapshotViews(_ items: [ScheduledInventorySnapshot]) -> [ScheduledInventorySnapshotView] {
        var views: [ScheduledInventorySnapshotView] = []
        for item in items {
            views.append(toScheduledInventorySnapshotView(item))
        }
        return views
    }

    static func sumScheduledInventorySnapshotView(_ view: ScheduledInventorySnapshotView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedLimit) + Double(parsedVisitMinutes) + Double(parsedRefills)
    }
}
