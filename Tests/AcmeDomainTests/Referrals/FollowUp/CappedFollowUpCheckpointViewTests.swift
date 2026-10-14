@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newCappedFollowUpCheckpoint("code-854", title: "title-643")
        let view = Referrals.toCappedFollowUpCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toCappedFollowUpCheckpointViews([item, item]).count == 2)
    }
}
