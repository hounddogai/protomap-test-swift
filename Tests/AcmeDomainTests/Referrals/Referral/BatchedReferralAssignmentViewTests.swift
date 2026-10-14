@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedReferralAssignment("code-934", label: "label-668")
        let view = Referrals.toBatchedReferralAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedReferralAssignmentViews([item, item]).count == 2)
    }
}
