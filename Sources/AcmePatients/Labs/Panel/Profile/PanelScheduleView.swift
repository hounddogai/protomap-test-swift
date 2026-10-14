import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel schedule.
    final class PanelScheduleView {
        var code: String
        var labelText: String
        var ceiling: String
        var budget: String
        var currency: String
        var timezone: String
        var maximumText: String
        var externalRef: String
        var ownerID: String
        var statusLabel: String

        init(code: String, labelText: String, ceiling: String, budget: String, currency: String, timezone: String, maximumText: String, externalRef: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ceiling = ceiling
            self.budget = budget
            self.currency = currency
            self.timezone = timezone
            self.maximumText = maximumText
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toPanelScheduleView(_ item: PanelSchedule) -> PanelScheduleView {
        return PanelScheduleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            budget: String(format: "%.2f", item.budget),
            currency: item.currency,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            maximumText: String(format: "%.2f", item.maximum),
            externalRef: item.externalRef,
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelScheduleViews(_ items: [PanelSchedule]) -> [PanelScheduleView] {
        var views: [PanelScheduleView] = []
        for item in items {
            views.append(toPanelScheduleView(item))
        }
        return views
    }

    static func sumPanelScheduleView(_ view: PanelScheduleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedBudget + parsedMaximum
    }
}
