@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newAdaptiveFollowUpMapping("code-786", label: "label-632")
        let view = Referrals.toAdaptiveFollowUpMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toAdaptiveFollowUpMappingViews([item, item]).count == 2)
    }
}
