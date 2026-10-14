@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityRequest("code-662", title: "title-516")
        let view = Referrals.toEligibilityRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityRequestViews([item, item]).count == 2)
    }
}
