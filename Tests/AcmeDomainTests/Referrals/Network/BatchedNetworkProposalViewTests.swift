@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedNetworkProposal("code-585", name: "name-704")
        let view = Referrals.toBatchedNetworkProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedNetworkProposalViews([item, item]).count == 2)
    }
}
