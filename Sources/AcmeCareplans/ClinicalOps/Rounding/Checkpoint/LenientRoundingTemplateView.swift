import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient rounding template.
    final class LenientRoundingTemplateView {
        var codeText: String
        var name: String
        var attempts: String
        var acuity: String
        var expiresAt: String
        var facility: String
        var approved: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, name: String, attempts: String, acuity: String, expiresAt: String, facility: String, approved: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.attempts = attempts
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.facility = facility
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRoundingTemplateView(_ item: LenientRoundingTemplate) -> LenientRoundingTemplateView {
        return LenientRoundingTemplateView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            attempts: String(item.attempts),
            acuity: String(item.acuity),
            expiresAt: String(item.expiresAt),
            facility: item.facility,
            approved: "\(item.approved)",
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRoundingTemplateViews(_ items: [LenientRoundingTemplate]) -> [LenientRoundingTemplateView] {
        var views: [LenientRoundingTemplateView] = []
        for item in items {
            views.append(toLenientRoundingTemplateView(item))
        }
        return views
    }

    static func sumLenientRoundingTemplateView(_ view: LenientRoundingTemplateView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity) + Double(parsedExpiresAt)
    }
}
