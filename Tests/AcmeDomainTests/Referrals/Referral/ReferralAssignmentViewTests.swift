@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralAssignment("code-34", title: "title-394")
        let view = Referrals.toReferralAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralAssignmentViews([item, item]).count == 2)
    }
}
