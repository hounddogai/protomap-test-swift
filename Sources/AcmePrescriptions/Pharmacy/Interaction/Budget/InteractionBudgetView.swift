import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction budget.
    final class InteractionBudgetView {
        var codeText: String
        var titleText: String
        var checksum: String
        var visitMinutesText: String
        var maximum: String
        var timezoneText: String
        var description: String
        var localeText: String
        var statusLabel: String

        init(codeText: String, titleText: String, checksum: String, visitMinutesText: String, maximum: String, timezoneText: String, description: String, localeText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.checksum = checksum
            self.visitMinutesText = visitMinutesText
            self.maximum = maximum
            self.timezoneText = timezoneText
            self.description = description
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionBudgetView(_ item: InteractionBudget) -> InteractionBudgetView {
        return InteractionBudgetView(
            codeText: item.code,
            titleText: item.title,
            checksum: item.checksum,
            visitMinutesText: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            timezoneText: item.timezone,
            description: Kit.Text.truncate(item.description, limit: 40),
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionBudgetViews(_ items: [InteractionBudget]) -> [InteractionBudgetView] {
        var views: [InteractionBudgetView] = []
        for item in items {
            views.append(toInteractionBudgetView(item))
        }
        return views
    }

    static func sumInteractionBudgetView(_ view: InteractionBudgetView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedVisitMinutes) + parsedMaximum
    }
}
