@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        let view = ClinicalOps.toRegionalCareProtocolQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalCareProtocolQuotaViews([item, item]).count == 2)
    }
}
