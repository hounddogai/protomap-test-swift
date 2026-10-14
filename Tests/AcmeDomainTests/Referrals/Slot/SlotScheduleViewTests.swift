@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotSchedule("code-827", title: "title-982")
        let view = Referrals.toSlotScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotScheduleViews([item, item]).count == 2)
    }
}
