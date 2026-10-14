import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall template.
    final class RecallTemplateView {
        var code: String
        var label: String
        var checksum: String
        var allergy: String
        var facility: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, allergy: String, facility: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.allergy = allergy
            self.facility = facility
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRecallTemplateView(_ item: RecallTemplate) -> RecallTemplateView {
        return RecallTemplateView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            allergy: item.allergy,
            facility: item.facility,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallTemplateViews(_ items: [RecallTemplate]) -> [RecallTemplateView] {
        var views: [RecallTemplateView] = []
        for item in items {
            views.append(toRecallTemplateView(item))
        }
        return views
    }

    static func sumRecallTemplateView(_ view: RecallTemplateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
