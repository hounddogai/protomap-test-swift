@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newNetworkAgreement("code-367", label: "label-694")
        let view = Referrals.toNetworkAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toNetworkAgreementViews([item, item]).count == 2)
    }
}
