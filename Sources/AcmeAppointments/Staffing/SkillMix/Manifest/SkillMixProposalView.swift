import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix proposal.
    final class SkillMixProposalView {
        var code: String
        var label: String
        var procedureCode: String
        var pinned: String
        var attempts: String
        var diagnosisCode: String
        var discountText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, pinned: String, attempts: String, diagnosisCode: String, discountText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.pinned = pinned
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.discountText = discountText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixProposalView(_ item: SkillMixProposal) -> SkillMixProposalView {
        return SkillMixProposalView(
            code: item.code,
            label: item.label,
            procedureCode: item.procedureCode,
            pinned: "\(item.pinned)",
            attempts: String(item.attempts),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            discountText: String(format: "%.2f", item.discount),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixProposalViews(_ items: [SkillMixProposal]) -> [SkillMixProposalView] {
        var views: [SkillMixProposalView] = []
        for item in items {
            views.append(toSkillMixProposalView(item))
        }
        return views
    }

    static func sumSkillMixProposalView(_ view: SkillMixProposalView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedAttempts) + parsedDiscount + Double(parsedCreatedAt)
    }
}
