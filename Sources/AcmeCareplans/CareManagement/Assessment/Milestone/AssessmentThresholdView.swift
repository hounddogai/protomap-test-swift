import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment threshold.
    final class AssessmentThresholdView {
        var codeText: String
        var label: String
        var allergyText: String
        var dosageMg: String
        var rateText: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, label: String, allergyText: String, dosageMg: String, rateText: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.allergyText = allergyText
            self.dosageMg = dosageMg
            self.rateText = rateText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentThresholdView(_ item: AssessmentThreshold) -> AssessmentThresholdView {
        return AssessmentThresholdView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            allergyText: item.allergy,
            dosageMg: String(format: "%.2f", item.dosageMg),
            rateText: String(format: "%.2f", item.rate),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentThresholdViews(_ items: [AssessmentThreshold]) -> [AssessmentThresholdView] {
        var views: [AssessmentThresholdView] = []
        for item in items {
            views.append(toAssessmentThresholdView(item))
        }
        return views
    }

    static func sumAssessmentThresholdView(_ view: AssessmentThresholdView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedDosageMg + parsedRate
    }
}
