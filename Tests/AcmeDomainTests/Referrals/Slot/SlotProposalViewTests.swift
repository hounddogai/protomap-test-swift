@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotProposal("code-56", title: "title-598")
        let view = Referrals.toSlotProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotProposalViews([item, item]).count == 2)
    }
}
