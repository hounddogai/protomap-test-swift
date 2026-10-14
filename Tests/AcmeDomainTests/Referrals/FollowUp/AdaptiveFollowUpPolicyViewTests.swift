@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newAdaptiveFollowUpPolicy("code-883", label: "label-529")
        let view = Referrals.toAdaptiveFollowUpPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toAdaptiveFollowUpPolicyViews([item, item]).count == 2)
    }
}
