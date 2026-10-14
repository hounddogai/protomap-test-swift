@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityThreshold("code-159", label: "label-183")
        let view = Referrals.toEligibilityThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityThresholdViews([item, item]).count == 2)
    }
}
