import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default proxy proposal.
    final class DefaultProxyProposalView {
        var code: String
        var label: String
        var amountText: String
        var procedureCodeText: String
        var specialty: String
        var reviewerText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, label: String, amountText: String, procedureCodeText: String, specialty: String, reviewerText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amountText = amountText
            self.procedureCodeText = procedureCodeText
            self.specialty = specialty
            self.reviewerText = reviewerText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProxyProposalView(_ item: DefaultProxyProposal) -> DefaultProxyProposalView {
        return DefaultProxyProposalView(
            code: item.code,
            label: item.label,
            amountText: String(format: "%.2f", item.amount),
            procedureCodeText: item.procedureCode,
            specialty: item.specialty,
            reviewerText: item.reviewer,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProxyProposalViews(_ items: [DefaultProxyProposal]) -> [DefaultProxyProposalView] {
        var views: [DefaultProxyProposalView] = []
        for item in items {
            views.append(toDefaultProxyProposalView(item))
        }
        return views
    }

    static func sumDefaultProxyProposalView(_ view: DefaultProxyProposalView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedAmount + Double(parsedCapacity)
    }
}
