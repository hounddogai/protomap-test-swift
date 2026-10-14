@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralProposal("code-516", title: "title-154")
        let view = Referrals.toReferralProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralProposalViews([item, item]).count == 2)
    }
}
