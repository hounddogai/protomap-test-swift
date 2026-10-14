@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        let view = Referrals.toPendingEligibilityAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingEligibilityAssignmentViews([item, item]).count == 2)
    }
}
