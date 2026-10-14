@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFallbackNetworkSchedule("code-824", name: "name-436")
        let view = Referrals.toFallbackNetworkScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFallbackNetworkScheduleViews([item, item]).count == 2)
    }
}
