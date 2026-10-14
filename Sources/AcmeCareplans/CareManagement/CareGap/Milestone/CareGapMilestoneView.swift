import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap milestone.
    final class CareGapMilestoneView {
        var codeText: String
        var name: String
        var specialty: String
        var score: String
        var unit: String
        var description: String
        var sequenceText: String
        var copay: String
        var refillsText: String
        var statusLabel: String

        init(codeText: String, name: String, specialty: String, score: String, unit: String, description: String, sequenceText: String, copay: String, refillsText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialty = specialty
            self.score = score
            self.unit = unit
            self.description = description
            self.sequenceText = sequenceText
            self.copay = copay
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapMilestoneView(_ item: CareGapMilestone) -> CareGapMilestoneView {
        return CareGapMilestoneView(
            codeText: item.code,
            name: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            score: String(format: "%.2f", item.score),
            unit: item.unit,
            description: item.description,
            sequenceText: String(item.sequence),
            copay: String(format: "%.2f", item.copay),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapMilestoneViews(_ items: [CareGapMilestone]) -> [CareGapMilestoneView] {
        var views: [CareGapMilestoneView] = []
        for item in items {
            views.append(toCareGapMilestoneView(item))
        }
        return views
    }

    static func sumCareGapMilestoneView(_ view: CareGapMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedScore + Double(parsedSequence) + parsedCopay
    }
}
