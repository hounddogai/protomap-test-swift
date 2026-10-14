import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime budget.
    final class OvertimeBudgetView {
        var code: String
        var name: String
        var floorValueText: String
        var clinicianIDText: String
        var durationMinutes: String
        var encounterID: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, floorValueText: String, clinicianIDText: String, durationMinutes: String, encounterID: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValueText = floorValueText
            self.clinicianIDText = clinicianIDText
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeBudgetView(_ item: OvertimeBudget) -> OvertimeBudgetView {
        return OvertimeBudgetView(
            code: item.code,
            name: item.name,
            floorValueText: String(format: "%.2f", item.floorValue),
            clinicianIDText: item.clinicianID,
            durationMinutes: String(item.durationMinutes),
            encounterID: item.encounterID,
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeBudgetViews(_ items: [OvertimeBudget]) -> [OvertimeBudgetView] {
        var views: [OvertimeBudgetView] = []
        for item in items {
            views.append(toOvertimeBudgetView(item))
        }
        return views
    }

    static func sumOvertimeBudgetView(_ view: OvertimeBudgetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedFloorValue + Double(parsedDurationMinutes)
    }
}
