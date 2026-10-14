@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedSlotLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Referrals.newWeightedSlotLedger("code-363", label: "label-801")
        let view = Referrals.toWeightedSlotLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Referrals.toWeightedSlotLedgerViews([item, item]).count == 2)
    }
}
