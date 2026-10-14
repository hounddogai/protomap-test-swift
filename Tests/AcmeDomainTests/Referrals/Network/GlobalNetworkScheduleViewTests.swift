@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newGlobalNetworkSchedule("code-787", name: "name-817")
        let view = Referrals.toGlobalNetworkScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toGlobalNetworkScheduleViews([item, item]).count == 2)
    }
}
