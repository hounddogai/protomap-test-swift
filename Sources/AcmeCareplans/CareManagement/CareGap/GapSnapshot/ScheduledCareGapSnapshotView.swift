import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled care gap snapshot.
    final class ScheduledCareGapSnapshotView {
        var code: String
        var title: String
        var floorValue: String
        var country: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, country: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.country = country
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareGapSnapshotView(_ item: ScheduledCareGapSnapshot) -> ScheduledCareGapSnapshotView {
        return ScheduledCareGapSnapshotView(
            code: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            country: item.country,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareGapSnapshotViews(_ items: [ScheduledCareGapSnapshot]) -> [ScheduledCareGapSnapshotView] {
        var views: [ScheduledCareGapSnapshotView] = []
        for item in items {
            views.append(toScheduledCareGapSnapshotView(item))
        }
        return views
    }

    static func sumScheduledCareGapSnapshotView(_ view: ScheduledCareGapSnapshotView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
