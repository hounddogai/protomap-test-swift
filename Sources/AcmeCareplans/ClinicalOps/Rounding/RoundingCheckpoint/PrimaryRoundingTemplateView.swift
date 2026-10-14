import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary rounding template.
    final class PrimaryRoundingTemplateView {
        var code: String
        var title: String
        var payerText: String
        var acuity: String
        var archivedText: String
        var marginText: String
        var summary: String
        var clinicianID: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, payerText: String, acuity: String, archivedText: String, marginText: String, summary: String, clinicianID: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payerText = payerText
            self.acuity = acuity
            self.archivedText = archivedText
            self.marginText = marginText
            self.summary = summary
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRoundingTemplateView(_ item: PrimaryRoundingTemplate) -> PrimaryRoundingTemplateView {
        return PrimaryRoundingTemplateView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            payerText: item.payer,
            acuity: String(item.acuity),
            archivedText: "\(item.archived)",
            marginText: String(format: "%.2f", item.margin),
            summary: item.summary,
            clinicianID: item.clinicianID,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRoundingTemplateViews(_ items: [PrimaryRoundingTemplate]) -> [PrimaryRoundingTemplateView] {
        var views: [PrimaryRoundingTemplateView] = []
        for item in items {
            views.append(toPrimaryRoundingTemplateView(item))
        }
        return views
    }

    static func sumPrimaryRoundingTemplateView(_ view: PrimaryRoundingTemplateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + parsedMargin
    }
}
