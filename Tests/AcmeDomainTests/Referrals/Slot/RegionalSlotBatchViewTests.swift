@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRegionalSlotBatch("code-109", title: "title-403")
        let view = Referrals.toRegionalSlotBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRegionalSlotBatchViews([item, item]).count == 2)
    }
}
