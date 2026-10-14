@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkCheckpoint("code-148", name: "name-777")
        let view = Referrals.toNetworkCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkCheckpointViews([item, item]).count == 2)
    }
}
