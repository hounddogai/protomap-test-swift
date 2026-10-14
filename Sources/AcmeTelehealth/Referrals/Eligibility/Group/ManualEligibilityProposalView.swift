import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual eligibility proposal.
    final class ManualEligibilityProposalView {
        var code: String
        var title: String
        var attempts: String
        var facility: String
        var labelText: String
        var diagnosisCode: String
        var patientRef: String
        var allergy: String
        var timezone: String
        var source: String
        var checksumText: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, facility: String, labelText: String, diagnosisCode: String, patientRef: String, allergy: String, timezone: String, source: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.facility = facility
            self.labelText = labelText
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.allergy = allergy
            self.timezone = timezone
            self.source = source
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toManualEligibilityProposalView(_ item: ManualEligibilityProposal) -> ManualEligibilityProposalView {
        return ManualEligibilityProposalView(
            code: item.code,
            title: item.title,
            attempts: String(item.attempts),
            facility: item.facility,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            patientRef: item.patientRef,
            allergy: item.allergy,
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            source: Kit.Text.truncate(item.source, limit: 80),
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualEligibilityProposalViews(_ items: [ManualEligibilityProposal]) -> [ManualEligibilityProposalView] {
        var views: [ManualEligibilityProposalView] = []
        for item in items {
            views.append(toManualEligibilityProposalView(item))
        }
        return views
    }

    static func sumManualEligibilityProposalView(_ view: ManualEligibilityProposalView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
