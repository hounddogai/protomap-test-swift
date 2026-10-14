@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacySlotThreshold("code-992", label: "label-903")
        let view = Referrals.toLegacySlotThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacySlotThresholdViews([item, item]).count == 2)
    }
}
