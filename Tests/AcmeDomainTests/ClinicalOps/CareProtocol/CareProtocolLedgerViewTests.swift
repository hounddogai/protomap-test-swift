@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCareProtocolLedger("code-374", name: "name-187")
        let view = ClinicalOps.toCareProtocolLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCareProtocolLedgerViews([item, item]).count == 2)
    }
}
