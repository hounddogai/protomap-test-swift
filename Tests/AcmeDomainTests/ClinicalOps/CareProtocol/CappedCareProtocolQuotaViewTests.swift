@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedCareProtocolQuota("code-753", label: "label-426")
        let view = ClinicalOps.toCappedCareProtocolQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedCareProtocolQuotaViews([item, item]).count == 2)
    }
}
