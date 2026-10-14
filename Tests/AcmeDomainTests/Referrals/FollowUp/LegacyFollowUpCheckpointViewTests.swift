@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLegacyFollowUpCheckpoint("code-584", name: "name-673")
        let view = Referrals.toLegacyFollowUpCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLegacyFollowUpCheckpointViews([item, item]).count == 2)
    }
}
