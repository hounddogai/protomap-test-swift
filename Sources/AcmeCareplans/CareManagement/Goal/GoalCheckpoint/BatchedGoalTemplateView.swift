import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched goal template.
    final class BatchedGoalTemplateView {
        var code: String
        var name: String
        var dosageMg: String
        var specialty: String
        var copay: String
        var acuityText: String
        var graceDays: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, specialty: String, copay: String, acuityText: String, graceDays: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.copay = copay
            self.acuityText = acuityText
            self.graceDays = graceDays
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedGoalTemplateView(_ item: BatchedGoalTemplate) -> BatchedGoalTemplateView {
        return BatchedGoalTemplateView(
            code: item.code,
            name: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            copay: String(format: "%.2f", item.copay),
            acuityText: String(item.acuity),
            graceDays: String(item.graceDays),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedGoalTemplateViews(_ items: [BatchedGoalTemplate]) -> [BatchedGoalTemplateView] {
        var views: [BatchedGoalTemplateView] = []
        for item in items {
            views.append(toBatchedGoalTemplateView(item))
        }
        return views
    }

    static func sumBatchedGoalTemplateView(_ view: BatchedGoalTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedDosageMg + parsedCopay + Double(parsedAcuity)
    }
}
