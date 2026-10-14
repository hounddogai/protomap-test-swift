import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling substitution rule.
    final class RollingSubstitutionRuleView {
        var codeText: String
        var nameText: String
        var procedureCodeText: String
        var updatedAtText: String
        var specialtyText: String
        var maximumText: String
        var graceDays: String
        var payer: String
        var phone: String
        var sourceText: String
        var statusLabel: String

        init(codeText: String, nameText: String, procedureCodeText: String, updatedAtText: String, specialtyText: String, maximumText: String, graceDays: String, payer: String, phone: String, sourceText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.procedureCodeText = procedureCodeText
            self.updatedAtText = updatedAtText
            self.specialtyText = specialtyText
            self.maximumText = maximumText
            self.graceDays = graceDays
            self.payer = payer
            self.phone = phone
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSubstitutionRuleView(_ item: RollingSubstitutionRule) -> RollingSubstitutionRuleView {
        return RollingSubstitutionRuleView(
            codeText: item.code,
            nameText: item.name,
            procedureCodeText: item.procedureCode,
            updatedAtText: String(item.updatedAt),
            specialtyText: item.specialty,
            maximumText: String(format: "%.2f", item.maximum),
            graceDays: String(item.graceDays),
            payer: item.payer,
            phone: item.phone,
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSubstitutionRuleViews(_ items: [RollingSubstitutionRule]) -> [RollingSubstitutionRuleView] {
        var views: [RollingSubstitutionRuleView] = []
        for item in items {
            views.append(toRollingSubstitutionRuleView(item))
        }
        return views
    }

    static func sumRollingSubstitutionRuleView(_ view: RollingSubstitutionRuleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMaximum + Double(parsedGraceDays)
    }
}
