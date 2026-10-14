@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        let view = Referrals.toStrictSlotRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictSlotRecordViews([item, item]).count == 2)
    }
}
