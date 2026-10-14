import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution proposal.
    final class SubstitutionProposalView {
        var code: String
        var titleText: String
        var copay: String
        var procedureCodeText: String
        var acuity: String
        var statusLabel: String

        init(code: String, titleText: String, copay: String, procedureCodeText: String, acuity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.copay = copay
            self.procedureCodeText = procedureCodeText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionProposalView(_ item: SubstitutionProposal) -> SubstitutionProposalView {
        return SubstitutionProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            procedureCodeText: item.procedureCode,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionProposalViews(_ items: [SubstitutionProposal]) -> [SubstitutionProposalView] {
        var views: [SubstitutionProposalView] = []
        for item in items {
            views.append(toSubstitutionProposalView(item))
        }
        return views
    }

    static func sumSubstitutionProposalView(_ view: SubstitutionProposalView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedCopay + Double(parsedAcuity)
    }
}
