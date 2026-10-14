import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial profile.
    final class DenialProfileView {
        var codeText: String
        var label: String
        var diagnosisCode: String
        var budget: String
        var sequenceText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCode: String, budget: String, sequenceText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.sequenceText = sequenceText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toDenialProfileView(_ item: DenialProfile) -> DenialProfileView {
        return DenialProfileView(
            codeText: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            budget: String(format: "%.2f", item.budget),
            sequenceText: String(item.sequence),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialProfileViews(_ items: [DenialProfile]) -> [DenialProfileView] {
        var views: [DenialProfileView] = []
        for item in items {
            views.append(toDenialProfileView(item))
        }
        return views
    }

    static func sumDenialProfileView(_ view: DenialProfileView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedBudget + Double(parsedSequence) + parsedDosageMg
    }
}
