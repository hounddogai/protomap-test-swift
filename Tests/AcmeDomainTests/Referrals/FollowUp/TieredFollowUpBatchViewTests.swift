@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        let view = Referrals.toTieredFollowUpBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toTieredFollowUpBatchViews([item, item]).count == 2)
    }
}
