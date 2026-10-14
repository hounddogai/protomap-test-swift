import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap snapshot.
    final class SeasonalCareGapSnapshotView {
        var code: String
        var name: String
        var checksumText: String
        var floorValue: String
        var channel: String
        var allergyText: String
        var activeText: String
        var statusLabel: String

        init(code: String, name: String, checksumText: String, floorValue: String, channel: String, allergyText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksumText = checksumText
            self.floorValue = floorValue
            self.channel = channel
            self.allergyText = allergyText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapSnapshotView(_ item: SeasonalCareGapSnapshot) -> SeasonalCareGapSnapshotView {
        return SeasonalCareGapSnapshotView(
            code: item.code,
            name: item.name,
            checksumText: item.checksum,
            floorValue: String(format: "%.2f", item.floorValue),
            channel: item.channel,
            allergyText: item.allergy,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapSnapshotViews(_ items: [SeasonalCareGapSnapshot]) -> [SeasonalCareGapSnapshotView] {
        var views: [SeasonalCareGapSnapshotView] = []
        for item in items {
            views.append(toSeasonalCareGapSnapshotView(item))
        }
        return views
    }

    static func sumSeasonalCareGapSnapshotView(_ view: SeasonalCareGapSnapshotView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
