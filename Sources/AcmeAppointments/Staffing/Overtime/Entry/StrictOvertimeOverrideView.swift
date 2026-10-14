import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict overtime override.
    final class StrictOvertimeOverrideView {
        var code: String
        var title: String
        var quantity: String
        var nameText: String
        var visitMinutesText: String
        var approved: String
        var procedureCodeText: String
        var costText: String
        var active: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, nameText: String, visitMinutesText: String, approved: String, procedureCodeText: String, costText: String, active: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.nameText = nameText
            self.visitMinutesText = visitMinutesText
            self.approved = approved
            self.procedureCodeText = procedureCodeText
            self.costText = costText
            self.active = active
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictOvertimeOverrideView(_ item: StrictOvertimeOverride) -> StrictOvertimeOverrideView {
        return StrictOvertimeOverrideView(
            code: item.code,
            title: item.title,
            quantity: String(item.quantity),
            nameText: item.name,
            visitMinutesText: String(item.visitMinutes),
            approved: "\(item.approved)",
            procedureCodeText: item.procedureCode,
            costText: String(format: "%.2f", item.cost),
            active: "\(item.active)",
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictOvertimeOverrideViews(_ items: [StrictOvertimeOverride]) -> [StrictOvertimeOverrideView] {
        var views: [StrictOvertimeOverrideView] = []
        for item in items {
            views.append(toStrictOvertimeOverrideView(item))
        }
        return views
    }

    static func sumStrictOvertimeOverrideView(_ view: StrictOvertimeOverrideView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedQuantity) + Double(parsedVisitMinutes) + parsedCost
    }
}
