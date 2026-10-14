@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacySlotRecord("code-527", title: "title-928")
        let view = Referrals.toLegacySlotRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacySlotRecordViews([item, item]).count == 2)
    }
}
