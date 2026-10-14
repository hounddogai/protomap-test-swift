import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program template.
    final class ProgramTemplateView {
        var code: String
        var name: String
        var patientRefText: String
        var threshold: String
        var reviewer: String
        var dosageMg: String
        var labelText: String
        var quantity: String
        var startsAt: String
        var refills: String
        var statusLabel: String

        init(code: String, name: String, patientRefText: String, threshold: String, reviewer: String, dosageMg: String, labelText: String, quantity: String, startsAt: String, refills: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRefText = patientRefText
            self.threshold = threshold
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.labelText = labelText
            self.quantity = quantity
            self.startsAt = startsAt
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toProgramTemplateView(_ item: ProgramTemplate) -> ProgramTemplateView {
        return ProgramTemplateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            patientRefText: item.patientRef,
            threshold: String(format: "%.2f", item.threshold),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            labelText: item.label,
            quantity: String(item.quantity),
            startsAt: String(item.startsAt),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramTemplateViews(_ items: [ProgramTemplate]) -> [ProgramTemplateView] {
        var views: [ProgramTemplateView] = []
        for item in items {
            views.append(toProgramTemplateView(item))
        }
        return views
    }

    static func sumProgramTemplateView(_ view: ProgramTemplateView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + parsedDosageMg + Double(parsedQuantity)
    }
}
