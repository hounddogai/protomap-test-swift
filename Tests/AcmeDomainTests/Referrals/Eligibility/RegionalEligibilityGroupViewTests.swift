@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalEligibilityGroup("code-723", label: "label-513")
        let view = Referrals.toRegionalEligibilityGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalEligibilityGroupViews([item, item]).count == 2)
    }
}
