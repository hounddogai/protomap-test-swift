import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched authorization preference.
    final class BatchedAuthorizationPreferenceView {
        var codeText: String
        var title: String
        var notes: String
        var acuityText: String
        var patientRefText: String
        var diagnosisCode: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, title: String, notes: String, acuityText: String, patientRefText: String, diagnosisCode: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.notes = notes
            self.acuityText = acuityText
            self.patientRefText = patientRefText
            self.diagnosisCode = diagnosisCode
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAuthorizationPreferenceView(_ item: BatchedAuthorizationPreference) -> BatchedAuthorizationPreferenceView {
        return BatchedAuthorizationPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            notes: item.notes,
            acuityText: String(item.acuity),
            patientRefText: item.patientRef,
            diagnosisCode: item.diagnosisCode,
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAuthorizationPreferenceViews(_ items: [BatchedAuthorizationPreference]) -> [BatchedAuthorizationPreferenceView] {
        var views: [BatchedAuthorizationPreferenceView] = []
        for item in items {
            views.append(toBatchedAuthorizationPreferenceView(item))
        }
        return views
    }

    static func sumBatchedAuthorizationPreferenceView(_ view: BatchedAuthorizationPreferenceView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
