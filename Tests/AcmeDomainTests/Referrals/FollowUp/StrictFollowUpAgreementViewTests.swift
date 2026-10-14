@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictFollowUpAgreement("code-480", name: "name-69")
        let view = Referrals.toStrictFollowUpAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictFollowUpAgreementViews([item, item]).count == 2)
    }
}
