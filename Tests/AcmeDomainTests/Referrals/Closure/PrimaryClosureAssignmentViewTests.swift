@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPrimaryClosureAssignment("code-918", title: "title-197")
        let view = Referrals.toPrimaryClosureAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPrimaryClosureAssignmentViews([item, item]).count == 2)
    }
}
