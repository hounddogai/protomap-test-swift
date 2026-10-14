@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityAllocation("code-567", title: "title-200")
        let view = Referrals.toEligibilityAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityAllocationViews([item, item]).count == 2)
    }
}
