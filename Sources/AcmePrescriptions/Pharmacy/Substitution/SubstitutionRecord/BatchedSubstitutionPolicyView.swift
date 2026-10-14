import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched substitution policy.
    final class BatchedSubstitutionPolicyView {
        var code: String
        var name: String
        var score: String
        var countryText: String
        var specialtyText: String
        var diagnosisCode: String
        var graceDays: String
        var maximum: String
        var source: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, score: String, countryText: String, specialtyText: String, diagnosisCode: String, graceDays: String, maximum: String, source: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.countryText = countryText
            self.specialtyText = specialtyText
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.maximum = maximum
            self.source = source
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSubstitutionPolicyView(_ item: BatchedSubstitutionPolicy) -> BatchedSubstitutionPolicyView {
        return BatchedSubstitutionPolicyView(
            code: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            countryText: item.country,
            specialtyText: item.specialty,
            diagnosisCode: item.diagnosisCode,
            graceDays: String(item.graceDays),
            maximum: String(format: "%.2f", item.maximum),
            source: Kit.Text.truncate(item.source, limit: 64),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSubstitutionPolicyViews(_ items: [BatchedSubstitutionPolicy]) -> [BatchedSubstitutionPolicyView] {
        var views: [BatchedSubstitutionPolicyView] = []
        for item in items {
            views.append(toBatchedSubstitutionPolicyView(item))
        }
        return views
    }

    static func sumBatchedSubstitutionPolicyView(_ view: BatchedSubstitutionPolicyView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedScore + Double(parsedGraceDays) + parsedMaximum
    }
}
