@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTieredHandoffLedger("code-43", name: "name-90")
        let view = ClinicalOps.toTieredHandoffLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTieredHandoffLedgerViews([item, item]).count == 2)
    }
}
