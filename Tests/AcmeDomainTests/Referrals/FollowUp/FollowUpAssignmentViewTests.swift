@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpAssignment("code-544", title: "title-947")
        let view = Referrals.toFollowUpAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpAssignmentViews([item, item]).count == 2)
    }
}
