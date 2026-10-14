@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newReferralTemplate("code-625", title: "title-697")
        let view = Referrals.toReferralTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toReferralTemplateViews([item, item]).count == 2)
    }
}
