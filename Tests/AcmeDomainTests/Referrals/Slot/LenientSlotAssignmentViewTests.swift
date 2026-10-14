@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newLenientSlotAssignment("code-739", name: "name-943")
        let view = Referrals.toLenientSlotAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toLenientSlotAssignmentViews([item, item]).count == 2)
    }
}
