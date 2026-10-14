@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRoundingLedger("code-271", label: "label-307")
        let view = ClinicalOps.toRoundingLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRoundingLedgerViews([item, item]).count == 2)
    }
}
