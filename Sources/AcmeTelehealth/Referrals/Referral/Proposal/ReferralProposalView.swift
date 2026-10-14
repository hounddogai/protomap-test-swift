import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral proposal.
    final class ReferralProposalView {
        var code: String
        var titleText: String
        var approvedText: String
        var visitMinutesText: String
        var quantity: String
        var encounterID: String
        var active: String
        var currency: String
        var payer: String
        var ratio: String
        var phoneText: String
        var statusLabel: String

        init(code: String, titleText: String, approvedText: String, visitMinutesText: String, quantity: String, encounterID: String, active: String, currency: String, payer: String, ratio: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approvedText = approvedText
            self.visitMinutesText = visitMinutesText
            self.quantity = quantity
            self.encounterID = encounterID
            self.active = active
            self.currency = currency
            self.payer = payer
            self.ratio = ratio
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralProposalView(_ item: ReferralProposal) -> ReferralProposalView {
        return ReferralProposalView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            approvedText: "\(item.approved)",
            visitMinutesText: String(item.visitMinutes),
            quantity: String(item.quantity),
            encounterID: item.encounterID,
            active: "\(item.active)",
            currency: Kit.Text.truncate(item.currency, limit: 64),
            payer: item.payer,
            ratio: String(format: "%.2f", item.ratio),
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralProposalViews(_ items: [ReferralProposal]) -> [ReferralProposalView] {
        var views: [ReferralProposalView] = []
        for item in items {
            views.append(toReferralProposalView(item))
        }
        return views
    }

    static func sumReferralProposalView(_ view: ReferralProposalView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedQuantity) + parsedRatio
    }
}
