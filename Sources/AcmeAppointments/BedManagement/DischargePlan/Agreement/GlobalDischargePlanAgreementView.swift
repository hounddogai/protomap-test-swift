import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global discharge plan agreement.
    final class GlobalDischargePlanAgreementView {
        var code: String
        var label: String
        var copayText: String
        var payer: String
        var approved: String
        var allergy: String
        var acuity: String
        var descriptionText: String
        var dosageMgText: String
        var refills: String
        var statusLabel: String

        init(code: String, label: String, copayText: String, payer: String, approved: String, allergy: String, acuity: String, descriptionText: String, dosageMgText: String, refills: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copayText = copayText
            self.payer = payer
            self.approved = approved
            self.allergy = allergy
            self.acuity = acuity
            self.descriptionText = descriptionText
            self.dosageMgText = dosageMgText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDischargePlanAgreementView(_ item: GlobalDischargePlanAgreement) -> GlobalDischargePlanAgreementView {
        return GlobalDischargePlanAgreementView(
            code: item.code,
            label: item.label,
            copayText: String(format: "%.2f", item.copay),
            payer: item.payer,
            approved: "\(item.approved)",
            allergy: item.allergy,
            acuity: String(item.acuity),
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDischargePlanAgreementViews(_ items: [GlobalDischargePlanAgreement]) -> [GlobalDischargePlanAgreementView] {
        var views: [GlobalDischargePlanAgreementView] = []
        for item in items {
            views.append(toGlobalDischargePlanAgreementView(item))
        }
        return views
    }

    static func sumGlobalDischargePlanAgreementView(_ view: GlobalDischargePlanAgreementView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCopay + Double(parsedAcuity) + parsedDosageMg
    }
}
