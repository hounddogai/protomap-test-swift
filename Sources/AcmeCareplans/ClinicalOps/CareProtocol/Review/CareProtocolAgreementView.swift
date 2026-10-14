import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol agreement.
    final class CareProtocolAgreementView {
        var code: String
        var title: String
        var rate: String
        var name: String
        var externalRef: String
        var minimum: String
        var budget: String
        var payer: String
        var limit: String
        var archived: String
        var refillsText: String
        var statusLabel: String

        init(code: String, title: String, rate: String, name: String, externalRef: String, minimum: String, budget: String, payer: String, limit: String, archived: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rate = rate
            self.name = name
            self.externalRef = externalRef
            self.minimum = minimum
            self.budget = budget
            self.payer = payer
            self.limit = limit
            self.archived = archived
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolAgreementView(_ item: CareProtocolAgreement) -> CareProtocolAgreementView {
        return CareProtocolAgreementView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            name: item.name,
            externalRef: item.externalRef,
            minimum: String(format: "%.2f", item.minimum),
            budget: String(format: "%.2f", item.budget),
            payer: item.payer,
            limit: String(item.limit),
            archived: "\(item.archived)",
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolAgreementViews(_ items: [CareProtocolAgreement]) -> [CareProtocolAgreementView] {
        var views: [CareProtocolAgreementView] = []
        for item in items {
            views.append(toCareProtocolAgreementView(item))
        }
        return views
    }

    static func sumCareProtocolAgreementView(_ view: CareProtocolAgreementView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRate + parsedMinimum + parsedBudget
    }
}
