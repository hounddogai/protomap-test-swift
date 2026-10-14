import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual follow up rule.
    final class ManualFollowUpRuleView {
        var code: String
        var name: String
        var archived: String
        var allergyText: String
        var dosageMg: String
        var approved: String
        var contactEmail: String
        var attempts: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, archived: String, allergyText: String, dosageMg: String, approved: String, contactEmail: String, attempts: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.allergyText = allergyText
            self.dosageMg = dosageMg
            self.approved = approved
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toManualFollowUpRuleView(_ item: ManualFollowUpRule) -> ManualFollowUpRuleView {
        return ManualFollowUpRuleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            archived: "\(item.archived)",
            allergyText: item.allergy,
            dosageMg: String(format: "%.2f", item.dosageMg),
            approved: "\(item.approved)",
            contactEmail: item.contactEmail,
            attempts: String(item.attempts),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFollowUpRuleViews(_ items: [ManualFollowUpRule]) -> [ManualFollowUpRuleView] {
        var views: [ManualFollowUpRuleView] = []
        for item in items {
            views.append(toManualFollowUpRuleView(item))
        }
        return views
    }

    static func sumManualFollowUpRuleView(_ view: ManualFollowUpRuleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDosageMg + Double(parsedAttempts)
    }
}
