import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol proposal.
    final class CareProtocolProposalView {
        var codeText: String
        var name: String
        var contactEmail: String
        var allergy: String
        var durationMinutes: String
        var encounterID: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, contactEmail: String, allergy: String, durationMinutes: String, encounterID: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolProposalView(_ item: CareProtocolProposal) -> CareProtocolProposalView {
        return CareProtocolProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            allergy: item.allergy,
            durationMinutes: String(item.durationMinutes),
            encounterID: item.encounterID,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolProposalViews(_ items: [CareProtocolProposal]) -> [CareProtocolProposalView] {
        var views: [CareProtocolProposalView] = []
        for item in items {
            views.append(toCareProtocolProposalView(item))
        }
        return views
    }

    static func sumCareProtocolProposalView(_ view: CareProtocolProposalView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedPriority)
    }
}
