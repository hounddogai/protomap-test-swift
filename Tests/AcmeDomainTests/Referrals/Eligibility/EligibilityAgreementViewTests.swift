@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        let view = Referrals.toEligibilityAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toEligibilityAgreementViews([item, item]).count == 2)
    }
}
