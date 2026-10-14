import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol draft.
    final class CareProtocolDraftView {
        var code: String
        var name: String
        var durationMinutesText: String
        var copayText: String
        var budget: String
        var priorityText: String
        var floorValueText: String
        var quantityText: String
        var statusLabel: String

        init(code: String, name: String, durationMinutesText: String, copayText: String, budget: String, priorityText: String, floorValueText: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutesText = durationMinutesText
            self.copayText = copayText
            self.budget = budget
            self.priorityText = priorityText
            self.floorValueText = floorValueText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolDraftView(_ item: CareProtocolDraft) -> CareProtocolDraftView {
        return CareProtocolDraftView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            durationMinutesText: String(item.durationMinutes),
            copayText: String(format: "%.2f", item.copay),
            budget: String(format: "%.2f", item.budget),
            priorityText: String(item.priority),
            floorValueText: String(format: "%.2f", item.floorValue),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolDraftViews(_ items: [CareProtocolDraft]) -> [CareProtocolDraftView] {
        var views: [CareProtocolDraftView] = []
        for item in items {
            views.append(toCareProtocolDraftView(item))
        }
        return views
    }

    static func sumCareProtocolDraftView(_ view: CareProtocolDraftView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedDurationMinutes) + parsedCopay + parsedBudget
    }
}
