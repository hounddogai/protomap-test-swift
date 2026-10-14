import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy care gap snapshot.
    final class LegacyCareGapSnapshotView {
        var code: String
        var label: String
        var phone: String
        var durationMinutes: String
        var attemptsText: String
        var floorValue: String
        var channel: String
        var statusLabel: String

        init(code: String, label: String, phone: String, durationMinutes: String, attemptsText: String, floorValue: String, channel: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phone = phone
            self.durationMinutes = durationMinutes
            self.attemptsText = attemptsText
            self.floorValue = floorValue
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareGapSnapshotView(_ item: LegacyCareGapSnapshot) -> LegacyCareGapSnapshotView {
        return LegacyCareGapSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            phone: Kit.Text.truncate(item.phone, limit: 64),
            durationMinutes: String(item.durationMinutes),
            attemptsText: String(item.attempts),
            floorValue: String(format: "%.2f", item.floorValue),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareGapSnapshotViews(_ items: [LegacyCareGapSnapshot]) -> [LegacyCareGapSnapshotView] {
        var views: [LegacyCareGapSnapshotView] = []
        for item in items {
            views.append(toLegacyCareGapSnapshotView(item))
        }
        return views
    }

    static func sumLegacyCareGapSnapshotView(_ view: LegacyCareGapSnapshotView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedAttempts) + parsedFloorValue
    }
}
