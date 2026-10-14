@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        let view = ClinicalOps.toTaskPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskPlanViews([item, item]).count == 2)
    }
}
