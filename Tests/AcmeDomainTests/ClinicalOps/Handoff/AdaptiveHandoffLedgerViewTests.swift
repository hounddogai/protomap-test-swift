@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveHandoffLedger("code-962", title: "title-497")
        let view = ClinicalOps.toAdaptiveHandoffLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveHandoffLedgerViews([item, item]).count == 2)
    }
}
