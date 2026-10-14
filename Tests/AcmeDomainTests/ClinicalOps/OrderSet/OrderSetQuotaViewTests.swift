@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newOrderSetQuota("code-163", label: "label-418")
        let view = ClinicalOps.toOrderSetQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toOrderSetQuotaViews([item, item]).count == 2)
    }
}
