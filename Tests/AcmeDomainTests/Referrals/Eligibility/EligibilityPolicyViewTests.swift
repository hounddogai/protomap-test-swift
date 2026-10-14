@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityPolicy("code-852", name: "name-562")
        let view = Referrals.toEligibilityPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityPolicyViews([item, item]).count == 2)
    }
}
