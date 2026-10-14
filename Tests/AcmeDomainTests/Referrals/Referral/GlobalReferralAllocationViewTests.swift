@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalReferralAllocation("code-401", label: "label-788")
        let view = Referrals.toGlobalReferralAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalReferralAllocationViews([item, item]).count == 2)
    }
}
