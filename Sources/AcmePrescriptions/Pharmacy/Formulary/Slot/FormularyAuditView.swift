import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary audit.
    final class FormularyAuditView {
        var code: String
        var label: String
        var patientRefText: String
        var ratio: String
        var countryText: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, label: String, patientRefText: String, ratio: String, countryText: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRefText = patientRefText
            self.ratio = ratio
            self.countryText = countryText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyAuditView(_ item: FormularyAudit) -> FormularyAuditView {
        return FormularyAuditView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            patientRefText: item.patientRef,
            ratio: String(format: "%.2f", item.ratio),
            countryText: Kit.Text.truncate(item.country, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyAuditViews(_ items: [FormularyAudit]) -> [FormularyAuditView] {
        var views: [FormularyAuditView] = []
        for item in items {
            views.append(toFormularyAuditView(item))
        }
        return views
    }

    static func sumFormularyAuditView(_ view: FormularyAuditView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedRatio + parsedDosageMg
    }
}
