@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newStrictSlotLedger("code-795", title: "title-306")
        let view = Referrals.toStrictSlotLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toStrictSlotLedgerViews([item, item]).count == 2)
    }
}
