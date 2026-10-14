@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedNetworkClaim("code-545", label: "label-679")
        let view = Referrals.toBatchedNetworkClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedNetworkClaimViews([item, item]).count == 2)
    }
}
