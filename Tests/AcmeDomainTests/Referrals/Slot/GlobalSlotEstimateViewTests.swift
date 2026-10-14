@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalSlotEstimate("code-24", title: "title-139")
        let view = Referrals.toGlobalSlotEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalSlotEstimateViews([item, item]).count == 2)
    }
}
