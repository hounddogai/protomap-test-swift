@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertLedger("code-112", name: "name-941")
        let view = ClinicalOps.toAlertLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertLedgerViews([item, item]).count == 2)
    }
}
