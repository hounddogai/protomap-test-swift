@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityProposal("code-408", label: "label-117")
        let view = Referrals.toEligibilityProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityProposalViews([item, item]).count == 2)
    }
}
