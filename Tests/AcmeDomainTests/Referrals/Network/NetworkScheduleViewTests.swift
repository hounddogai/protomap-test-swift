@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        let view = Referrals.toNetworkScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkScheduleViews([item, item]).count == 2)
    }
}
