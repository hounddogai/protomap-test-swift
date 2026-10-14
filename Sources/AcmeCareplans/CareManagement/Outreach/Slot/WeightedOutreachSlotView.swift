import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted outreach slot.
    final class WeightedOutreachSlotView {
        var codeText: String
        var label: String
        var updatedAt: String
        var contactEmail: String
        var channelText: String
        var quantity: String
        var diagnosisCodeText: String
        var currency: String
        var visibleText: String
        var categoryText: String
        var title: String
        var statusLabel: String

        init(codeText: String, label: String, updatedAt: String, contactEmail: String, channelText: String, quantity: String, diagnosisCodeText: String, currency: String, visibleText: String, categoryText: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.channelText = channelText
            self.quantity = quantity
            self.diagnosisCodeText = diagnosisCodeText
            self.currency = currency
            self.visibleText = visibleText
            self.categoryText = categoryText
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOutreachSlotView(_ item: WeightedOutreachSlot) -> WeightedOutreachSlotView {
        return WeightedOutreachSlotView(
            codeText: item.code,
            label: item.label,
            updatedAt: String(item.updatedAt),
            contactEmail: item.contactEmail,
            channelText: item.channel,
            quantity: String(item.quantity),
            diagnosisCodeText: item.diagnosisCode,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            visibleText: "\(item.visible)",
            categoryText: item.category,
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOutreachSlotViews(_ items: [WeightedOutreachSlot]) -> [WeightedOutreachSlotView] {
        var views: [WeightedOutreachSlotView] = []
        for item in items {
            views.append(toWeightedOutreachSlotView(item))
        }
        return views
    }

    static func sumWeightedOutreachSlotView(_ view: WeightedOutreachSlotView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedQuantity)
    }
}
