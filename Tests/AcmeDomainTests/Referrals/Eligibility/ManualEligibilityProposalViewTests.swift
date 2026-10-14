@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualEligibilityProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newManualEligibilityProposal("code-707", title: "title-563")
        let view = Referrals.toManualEligibilityProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toManualEligibilityProposalViews([item, item]).count == 2)
    }
}
