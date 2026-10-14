@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedReferralAllocation("code-989", name: "name-368")
        let view = Referrals.toCappedReferralAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedReferralAllocationViews([item, item]).count == 2)
    }
}
