@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newClosureAssignment("code-411", label: "label-394")
        let view = Referrals.toClosureAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toClosureAssignmentViews([item, item]).count == 2)
    }
}
