import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary shift window.
    final class PrimaryShiftWindowView {
        var code: String
        var label: String
        var encounterID: String
        var attempts: String
        var active: String
        var graceDays: String
        var facilityText: String
        var floorValue: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, attempts: String, active: String, graceDays: String, facilityText: String, floorValue: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.attempts = attempts
            self.active = active
            self.graceDays = graceDays
            self.facilityText = facilityText
            self.floorValue = floorValue
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryShiftWindowView(_ item: PrimaryShiftWindow) -> PrimaryShiftWindowView {
        return PrimaryShiftWindowView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            encounterID: item.encounterID,
            attempts: String(item.attempts),
            active: "\(item.active)",
            graceDays: String(item.graceDays),
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryShiftWindowViews(_ items: [PrimaryShiftWindow]) -> [PrimaryShiftWindowView] {
        var views: [PrimaryShiftWindowView] = []
        for item in items {
            views.append(toPrimaryShiftWindowView(item))
        }
        return views
    }

    static func sumPrimaryShiftWindowView(_ view: PrimaryShiftWindowView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedAttempts) + Double(parsedGraceDays) + parsedFloorValue
    }
}
