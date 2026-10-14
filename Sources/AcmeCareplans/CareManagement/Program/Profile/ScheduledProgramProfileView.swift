import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled program profile.
    final class ScheduledProgramProfileView {
        var code: String
        var title: String
        var specialtyText: String
        var patientRefText: String
        var costText: String
        var visibleText: String
        var amountText: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, specialtyText: String, patientRefText: String, costText: String, visibleText: String, amountText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialtyText = specialtyText
            self.patientRefText = patientRefText
            self.costText = costText
            self.visibleText = visibleText
            self.amountText = amountText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProgramProfileView(_ item: ScheduledProgramProfile) -> ScheduledProgramProfileView {
        return ScheduledProgramProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            specialtyText: item.specialty,
            patientRefText: item.patientRef,
            costText: String(format: "%.2f", item.cost),
            visibleText: "\(item.visible)",
            amountText: String(format: "%.2f", item.amount),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProgramProfileViews(_ items: [ScheduledProgramProfile]) -> [ScheduledProgramProfileView] {
        var views: [ScheduledProgramProfileView] = []
        for item in items {
            views.append(toScheduledProgramProfileView(item))
        }
        return views
    }

    static func sumScheduledProgramProfileView(_ view: ScheduledProgramProfileView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCost + parsedAmount + Double(parsedLimit)
    }
}
