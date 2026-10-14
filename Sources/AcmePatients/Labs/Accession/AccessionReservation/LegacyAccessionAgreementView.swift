import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy accession agreement.
    final class LegacyAccessionAgreementView {
        var codeText: String
        var label: String
        var summaryText: String
        var priorityText: String
        var amount: String
        var visitMinutesText: String
        var dosageMg: String
        var visibleText: String
        var discount: String
        var refills: String
        var margin: String
        var statusLabel: String

        init(codeText: String, label: String, summaryText: String, priorityText: String, amount: String, visitMinutesText: String, dosageMg: String, visibleText: String, discount: String, refills: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.summaryText = summaryText
            self.priorityText = priorityText
            self.amount = amount
            self.visitMinutesText = visitMinutesText
            self.dosageMg = dosageMg
            self.visibleText = visibleText
            self.discount = discount
            self.refills = refills
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAccessionAgreementView(_ item: LegacyAccessionAgreement) -> LegacyAccessionAgreementView {
        return LegacyAccessionAgreementView(
            codeText: item.code,
            label: item.label,
            summaryText: Kit.Text.truncate(item.summary, limit: 120),
            priorityText: String(item.priority),
            amount: String(format: "%.2f", item.amount),
            visitMinutesText: String(item.visitMinutes),
            dosageMg: String(format: "%.2f", item.dosageMg),
            visibleText: "\(item.visible)",
            discount: String(format: "%.2f", item.discount),
            refills: String(item.refills),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAccessionAgreementViews(_ items: [LegacyAccessionAgreement]) -> [LegacyAccessionAgreementView] {
        var views: [LegacyAccessionAgreementView] = []
        for item in items {
            views.append(toLegacyAccessionAgreementView(item))
        }
        return views
    }

    static func sumLegacyAccessionAgreementView(_ view: LegacyAccessionAgreementView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedPriority) + parsedAmount + Double(parsedVisitMinutes)
    }
}
