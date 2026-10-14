import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge budget.
    final class ChargeBudgetView {
        var code: String
        var name: String
        var priorityText: String
        var pinnedText: String
        var contactEmail: String
        var dosageMg: String
        var localeText: String
        var visible: String
        var archived: String
        var graceDays: String
        var channelText: String
        var statusLabel: String

        init(code: String, name: String, priorityText: String, pinnedText: String, contactEmail: String, dosageMg: String, localeText: String, visible: String, archived: String, graceDays: String, channelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.priorityText = priorityText
            self.pinnedText = pinnedText
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.localeText = localeText
            self.visible = visible
            self.archived = archived
            self.graceDays = graceDays
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeBudgetView(_ item: ChargeBudget) -> ChargeBudgetView {
        return ChargeBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            priorityText: String(item.priority),
            pinnedText: "\(item.pinned)",
            contactEmail: item.contactEmail,
            dosageMg: String(format: "%.2f", item.dosageMg),
            localeText: item.locale,
            visible: "\(item.visible)",
            archived: "\(item.archived)",
            graceDays: String(item.graceDays),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeBudgetViews(_ items: [ChargeBudget]) -> [ChargeBudgetView] {
        var views: [ChargeBudgetView] = []
        for item in items {
            views.append(toChargeBudgetView(item))
        }
        return views
    }

    static func sumChargeBudgetView(_ view: ChargeBudgetView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedPriority) + parsedDosageMg + Double(parsedGraceDays)
    }
}
