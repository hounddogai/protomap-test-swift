@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedNetworkSchedule("code-2", label: "label-966")
        let view = Referrals.toCappedNetworkScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedNetworkScheduleViews([item, item]).count == 2)
    }
}
