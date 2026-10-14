import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted study bundle.
    final class WeightedStudyBundleView {
        var codeText: String
        var labelText: String
        var capacity: String
        var dosageMg: String
        var procedureCodeText: String
        var bed: String
        var reviewer: String
        var sequenceText: String
        var expiresAt: String
        var amount: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, labelText: String, capacity: String, dosageMg: String, procedureCodeText: String, bed: String, reviewer: String, sequenceText: String, expiresAt: String, amount: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.capacity = capacity
            self.dosageMg = dosageMg
            self.procedureCodeText = procedureCodeText
            self.bed = bed
            self.reviewer = reviewer
            self.sequenceText = sequenceText
            self.expiresAt = expiresAt
            self.amount = amount
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedStudyBundleView(_ item: WeightedStudyBundle) -> WeightedStudyBundleView {
        return WeightedStudyBundleView(
            codeText: item.code,
            labelText: item.label,
            capacity: String(item.capacity),
            dosageMg: String(format: "%.2f", item.dosageMg),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            bed: item.bed,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            sequenceText: String(item.sequence),
            expiresAt: String(item.expiresAt),
            amount: String(format: "%.2f", item.amount),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedStudyBundleViews(_ items: [WeightedStudyBundle]) -> [WeightedStudyBundleView] {
        var views: [WeightedStudyBundleView] = []
        for item in items {
            views.append(toWeightedStudyBundleView(item))
        }
        return views
    }

    static func sumWeightedStudyBundleView(_ view: WeightedStudyBundleView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCapacity) + parsedDosageMg + Double(parsedSequence)
    }
}
