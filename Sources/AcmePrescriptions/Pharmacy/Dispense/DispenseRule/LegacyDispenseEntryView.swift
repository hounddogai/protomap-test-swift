import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy dispense entry.
    final class LegacyDispenseEntryView {
        var code: String
        var label: String
        var floorValue: String
        var notesText: String
        var encounterID: String
        var attempts: String
        var durationMinutes: String
        var maximum: String
        var statusLabel: String

        init(code: String, label: String, floorValue: String, notesText: String, encounterID: String, attempts: String, durationMinutes: String, maximum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.notesText = notesText
            self.encounterID = encounterID
            self.attempts = attempts
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDispenseEntryView(_ item: LegacyDispenseEntry) -> LegacyDispenseEntryView {
        return LegacyDispenseEntryView(
            code: item.code,
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            notesText: item.notes,
            encounterID: item.encounterID,
            attempts: String(item.attempts),
            durationMinutes: String(item.durationMinutes),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDispenseEntryViews(_ items: [LegacyDispenseEntry]) -> [LegacyDispenseEntryView] {
        var views: [LegacyDispenseEntryView] = []
        for item in items {
            views.append(toLegacyDispenseEntryView(item))
        }
        return views
    }

    static func sumLegacyDispenseEntryView(_ view: LegacyDispenseEntryView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedFloorValue + Double(parsedAttempts) + Double(parsedDurationMinutes)
    }
}
