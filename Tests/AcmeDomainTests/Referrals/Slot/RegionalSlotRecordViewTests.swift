@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalSlotRecord("code-461", name: "name-740")
        let view = Referrals.toRegionalSlotRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalSlotRecordViews([item, item]).count == 2)
    }
}
