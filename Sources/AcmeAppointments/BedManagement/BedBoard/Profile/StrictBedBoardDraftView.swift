import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict bed board draft.
    final class StrictBedBoardDraftView {
        var codeText: String
        var label: String
        var country: String
        var currencyText: String
        var category: String
        var contactEmail: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, country: String, currencyText: String, category: String, contactEmail: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.country = country
            self.currencyText = currencyText
            self.category = category
            self.contactEmail = contactEmail
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toStrictBedBoardDraftView(_ item: StrictBedBoardDraft) -> StrictBedBoardDraftView {
        return StrictBedBoardDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            country: item.country,
            currencyText: item.currency,
            category: item.category,
            contactEmail: item.contactEmail,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictBedBoardDraftViews(_ items: [StrictBedBoardDraft]) -> [StrictBedBoardDraftView] {
        var views: [StrictBedBoardDraftView] = []
        for item in items {
            views.append(toStrictBedBoardDraftView(item))
        }
        return views
    }

    static func sumStrictBedBoardDraftView(_ view: StrictBedBoardDraftView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
