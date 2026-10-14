@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newSlotCycle("code-66", name: "name-237")
        let view = Referrals.toSlotCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toSlotCycleViews([item, item]).count == 2)
    }
}
