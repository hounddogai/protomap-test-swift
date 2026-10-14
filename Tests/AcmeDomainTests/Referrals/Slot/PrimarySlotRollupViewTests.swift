@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimarySlotRollup("code-407", name: "name-63")
        let view = Referrals.toPrimarySlotRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimarySlotRollupViews([item, item]).count == 2)
    }
}
