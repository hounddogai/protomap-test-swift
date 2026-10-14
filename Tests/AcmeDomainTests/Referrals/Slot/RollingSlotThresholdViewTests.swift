@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingSlotThreshold("code-616", title: "title-35")
        let view = Referrals.toRollingSlotThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingSlotThresholdViews([item, item]).count == 2)
    }
}
