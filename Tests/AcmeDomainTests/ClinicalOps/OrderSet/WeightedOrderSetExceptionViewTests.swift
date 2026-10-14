@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedOrderSetException("code-699", label: "label-948")
        let view = ClinicalOps.toWeightedOrderSetExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedOrderSetExceptionViews([item, item]).count == 2)
    }
}
