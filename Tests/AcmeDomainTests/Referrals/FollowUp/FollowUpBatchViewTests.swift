@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpBatch("code-873", name: "name-245")
        let view = Referrals.toFollowUpBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpBatchViews([item, item]).count == 2)
    }
}
