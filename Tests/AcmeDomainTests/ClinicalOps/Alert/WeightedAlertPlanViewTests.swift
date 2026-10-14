@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedAlertPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedAlertPlan("code-700", title: "title-331")
        let view = ClinicalOps.toWeightedAlertPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedAlertPlanViews([item, item]).count == 2)
    }
}
