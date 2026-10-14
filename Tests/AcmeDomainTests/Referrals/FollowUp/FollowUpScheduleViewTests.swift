@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpSchedule("code-985", label: "label-862")
        let view = Referrals.toFollowUpScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpScheduleViews([item, item]).count == 2)
    }
}
