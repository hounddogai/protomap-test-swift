@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingSlotCheckpoint("code-753", name: "name-34")
        let view = Referrals.toRollingSlotCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingSlotCheckpointViews([item, item]).count == 2)
    }
}
