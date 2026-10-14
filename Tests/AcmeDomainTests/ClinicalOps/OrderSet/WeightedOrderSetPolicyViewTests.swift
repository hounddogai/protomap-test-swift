@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedOrderSetPolicy("code-605", label: "label-209")
        let view = ClinicalOps.toWeightedOrderSetPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedOrderSetPolicyViews([item, item]).count == 2)
    }
}
