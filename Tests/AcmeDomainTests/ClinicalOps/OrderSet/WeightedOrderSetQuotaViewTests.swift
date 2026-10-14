@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedOrderSetQuota("code-612", label: "label-346")
        let view = ClinicalOps.toWeightedOrderSetQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedOrderSetQuotaViews([item, item]).count == 2)
    }
}
