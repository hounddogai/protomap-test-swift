@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newFollowUpPolicy("code-506", label: "label-920")
        let view = Referrals.toFollowUpPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toFollowUpPolicyViews([item, item]).count == 2)
    }
}
