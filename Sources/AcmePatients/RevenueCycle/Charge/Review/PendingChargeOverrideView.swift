import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending charge override.
    final class PendingChargeOverrideView {
        var codeText: String
        var name: String
        var label: String
        var patientRef: String
        var specialtyText: String
        var contactEmail: String
        var diagnosisCode: String
        var graceDaysText: String
        var summary: String
        var ownerIDText: String
        var region: String
        var statusLabel: String

        init(codeText: String, name: String, label: String, patientRef: String, specialtyText: String, contactEmail: String, diagnosisCode: String, graceDaysText: String, summary: String, ownerIDText: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.label = label
            self.patientRef = patientRef
            self.specialtyText = specialtyText
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.graceDaysText = graceDaysText
            self.summary = summary
            self.ownerIDText = ownerIDText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toPendingChargeOverrideView(_ item: PendingChargeOverride) -> PendingChargeOverrideView {
        return PendingChargeOverrideView(
            codeText: item.code,
            name: item.name,
            label: Kit.Text.truncate(item.label, limit: 40),
            patientRef: item.patientRef,
            specialtyText: item.specialty,
            contactEmail: item.contactEmail,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            graceDaysText: String(item.graceDays),
            summary: item.summary,
            ownerIDText: item.ownerID,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingChargeOverrideViews(_ items: [PendingChargeOverride]) -> [PendingChargeOverrideView] {
        var views: [PendingChargeOverrideView] = []
        for item in items {
            views.append(toPendingChargeOverrideView(item))
        }
        return views
    }

    static func sumPendingChargeOverrideView(_ view: PendingChargeOverrideView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
