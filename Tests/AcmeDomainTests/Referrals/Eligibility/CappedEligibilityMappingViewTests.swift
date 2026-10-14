@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedEligibilityMapping("code-145", title: "title-858")
        let view = Referrals.toCappedEligibilityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedEligibilityMappingViews([item, item]).count == 2)
    }
}
