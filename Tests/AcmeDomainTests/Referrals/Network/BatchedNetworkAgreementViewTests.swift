@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newBatchedNetworkAgreement("code-181", label: "label-145")
        let view = Referrals.toBatchedNetworkAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toBatchedNetworkAgreementViews([item, item]).count == 2)
    }
}
