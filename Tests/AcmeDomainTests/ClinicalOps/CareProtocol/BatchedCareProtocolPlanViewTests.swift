@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newBatchedCareProtocolPlan("code-728", label: "label-890")
        let view = ClinicalOps.toBatchedCareProtocolPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toBatchedCareProtocolPlanViews([item, item]).count == 2)
    }
}
