import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility request.
    final class EligibilityRequestView {
        var codeText: String
        var titleText: String
        var channel: String
        var notesText: String
        var ownerID: String
        var name: String
        var description: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, titleText: String, channel: String, notesText: String, ownerID: String, name: String, description: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.channel = channel
            self.notesText = notesText
            self.ownerID = ownerID
            self.name = name
            self.description = description
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityRequestView(_ item: EligibilityRequest) -> EligibilityRequestView {
        return EligibilityRequestView(
            codeText: item.code,
            titleText: item.title,
            channel: item.channel,
            notesText: item.notes,
            ownerID: item.ownerID,
            name: item.name,
            description: item.description,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityRequestViews(_ items: [EligibilityRequest]) -> [EligibilityRequestView] {
        var views: [EligibilityRequestView] = []
        for item in items {
            views.append(toEligibilityRequestView(item))
        }
        return views
    }

    static func sumEligibilityRequestView(_ view: EligibilityRequestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
