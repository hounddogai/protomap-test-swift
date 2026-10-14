@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCareProtocolBatch("code-504", name: "name-691")
        let view = ClinicalOps.toCareProtocolBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCareProtocolBatchViews([item, item]).count == 2)
    }
}
