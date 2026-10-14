import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form proposal.
    final class PrimaryConsentFormProposalView {
        var codeText: String
        var nameText: String
        var floorValue: String
        var minimumText: String
        var margin: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, nameText: String, floorValue: String, minimumText: String, margin: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.floorValue = floorValue
            self.minimumText = minimumText
            self.margin = margin
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormProposalView(_ item: PrimaryConsentFormProposal) -> PrimaryConsentFormProposalView {
        return PrimaryConsentFormProposalView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            minimumText: String(format: "%.2f", item.minimum),
            margin: String(format: "%.2f", item.margin),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormProposalViews(_ items: [PrimaryConsentFormProposal]) -> [PrimaryConsentFormProposalView] {
        var views: [PrimaryConsentFormProposalView] = []
        for item in items {
            views.append(toPrimaryConsentFormProposalView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormProposalView(_ view: PrimaryConsentFormProposalView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedFloorValue + parsedMinimum + parsedMargin
    }
}
