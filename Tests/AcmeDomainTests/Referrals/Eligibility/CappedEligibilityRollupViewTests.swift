@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedEligibilityRollup("code-176", label: "label-680")
        let view = Referrals.toCappedEligibilityRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedEligibilityRollupViews([item, item]).count == 2)
    }
}
