@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newRollingSlotAgreement("code-323", name: "name-513")
        let view = Referrals.toRollingSlotAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toRollingSlotAgreementViews([item, item]).count == 2)
    }
}
