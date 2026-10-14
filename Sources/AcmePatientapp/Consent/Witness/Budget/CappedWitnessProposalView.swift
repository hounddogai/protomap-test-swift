import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped witness proposal.
    final class CappedWitnessProposalView {
        var code: String
        var name: String
        var unit: String
        var graceDays: String
        var archived: String
        var phone: String
        var refills: String
        var sequence: String
        var acuity: String
        var version: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, unit: String, graceDays: String, archived: String, phone: String, refills: String, sequence: String, acuity: String, version: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unit = unit
            self.graceDays = graceDays
            self.archived = archived
            self.phone = phone
            self.refills = refills
            self.sequence = sequence
            self.acuity = acuity
            self.version = version
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedWitnessProposalView(_ item: CappedWitnessProposal) -> CappedWitnessProposalView {
        return CappedWitnessProposalView(
            code: item.code,
            name: item.name,
            unit: item.unit,
            graceDays: String(item.graceDays),
            archived: "\(item.archived)",
            phone: item.phone,
            refills: String(item.refills),
            sequence: String(item.sequence),
            acuity: String(item.acuity),
            version: String(item.version),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedWitnessProposalViews(_ items: [CappedWitnessProposal]) -> [CappedWitnessProposalView] {
        var views: [CappedWitnessProposalView] = []
        for item in items {
            views.append(toCappedWitnessProposalView(item))
        }
        return views
    }

    static func sumCappedWitnessProposalView(_ view: CappedWitnessProposalView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRefills) + Double(parsedSequence)
    }
}
