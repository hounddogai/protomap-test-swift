@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingClosureProposal("code-94", label: "label-599")
        let view = Referrals.toRollingClosureProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingClosureProposalViews([item, item]).count == 2)
    }
}
