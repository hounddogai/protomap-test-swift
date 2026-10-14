@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedSlotRecord("code-275", title: "title-891")
        let view = Referrals.toBatchedSlotRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedSlotRecordViews([item, item]).count == 2)
    }
}
