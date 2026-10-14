@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictSlotBatch("code-351", label: "label-545")
        let view = Referrals.toStrictSlotBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictSlotBatchViews([item, item]).count == 2)
    }
}
