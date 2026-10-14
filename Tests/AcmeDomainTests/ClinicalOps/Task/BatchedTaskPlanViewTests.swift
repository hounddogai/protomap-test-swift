@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        let view = ClinicalOps.toBatchedTaskPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toBatchedTaskPlanViews([item, item]).count == 2)
    }
}
