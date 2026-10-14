@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newPendingReferralLedger("code-97", label: "label-68")
        let view = Referrals.toPendingReferralLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toPendingReferralLedgerViews([item, item]).count == 2)
    }
}
