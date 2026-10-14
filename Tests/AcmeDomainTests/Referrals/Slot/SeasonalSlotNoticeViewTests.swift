@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalSlotNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSeasonalSlotNotice("code-188", label: "label-768")
        let view = Referrals.toSeasonalSlotNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSeasonalSlotNoticeViews([item, item]).count == 2)
    }
}
