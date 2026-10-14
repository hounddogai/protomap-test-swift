import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap proposal.
    final class CareGapProposalView {
        var code: String
        var label: String
        var allergyText: String
        var endsAt: String
        var patientRef: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, label: String, allergyText: String, endsAt: String, patientRef: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergyText = allergyText
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapProposalView(_ item: CareGapProposal) -> CareGapProposalView {
        return CareGapProposalView(
            code: item.code,
            label: item.label,
            allergyText: item.allergy,
            endsAt: String(item.endsAt),
            patientRef: item.patientRef,
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapProposalViews(_ items: [CareGapProposal]) -> [CareGapProposalView] {
        var views: [CareGapProposalView] = []
        for item in items {
            views.append(toCareGapProposalView(item))
        }
        return views
    }

    static func sumCareGapProposalView(_ view: CareGapProposalView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedAttempts)
    }
}
