@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyHandoffLedger("code-507", label: "label-692")
        let view = ClinicalOps.toLegacyHandoffLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyHandoffLedgerViews([item, item]).count == 2)
    }
}
