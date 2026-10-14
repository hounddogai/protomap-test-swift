@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureProposal("code-909", title: "title-314")
        let view = Referrals.toClosureProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureProposalViews([item, item]).count == 2)
    }
}
