import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up override.
    final class FollowUpOverrideView {
        var codeText: String
        var label: String
        var copay: String
        var patientRef: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, label: String, copay: String, patientRef: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.copay = copay
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpOverrideView(_ item: FollowUpOverride) -> FollowUpOverrideView {
        return FollowUpOverrideView(
            codeText: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            patientRef: item.patientRef,
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpOverrideViews(_ items: [FollowUpOverride]) -> [FollowUpOverrideView] {
        var views: [FollowUpOverrideView] = []
        for item in items {
            views.append(toFollowUpOverrideView(item))
        }
        return views
    }

    static func sumFollowUpOverrideView(_ view: FollowUpOverrideView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
