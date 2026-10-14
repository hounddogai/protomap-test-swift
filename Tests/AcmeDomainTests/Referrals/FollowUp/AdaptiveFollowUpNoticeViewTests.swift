@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newAdaptiveFollowUpNotice("code-44", label: "label-559")
        let view = Referrals.toAdaptiveFollowUpNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toAdaptiveFollowUpNoticeViews([item, item]).count == 2)
    }
}
