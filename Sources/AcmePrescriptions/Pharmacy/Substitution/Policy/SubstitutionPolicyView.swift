import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution policy.
    final class SubstitutionPolicyView {
        var codeText: String
        var titleText: String
        var specialty: String
        var externalRefText: String
        var scoreText: String
        var diagnosisCodeText: String
        var quantity: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, titleText: String, specialty: String, externalRefText: String, scoreText: String, diagnosisCodeText: String, quantity: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.specialty = specialty
            self.externalRefText = externalRefText
            self.scoreText = scoreText
            self.diagnosisCodeText = diagnosisCodeText
            self.quantity = quantity
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionPolicyView(_ item: SubstitutionPolicy) -> SubstitutionPolicyView {
        return SubstitutionPolicyView(
            codeText: item.code,
            titleText: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            externalRefText: item.externalRef,
            scoreText: String(format: "%.2f", item.score),
            diagnosisCodeText: item.diagnosisCode,
            quantity: String(item.quantity),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionPolicyViews(_ items: [SubstitutionPolicy]) -> [SubstitutionPolicyView] {
        var views: [SubstitutionPolicyView] = []
        for item in items {
            views.append(toSubstitutionPolicyView(item))
        }
        return views
    }

    static func sumSubstitutionPolicyView(_ view: SubstitutionPolicyView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedScore + Double(parsedQuantity) + parsedCopay
    }
}
