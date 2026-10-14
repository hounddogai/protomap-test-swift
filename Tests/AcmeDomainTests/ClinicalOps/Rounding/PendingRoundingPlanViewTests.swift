@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingRoundingPlan("code-978", title: "title-573")
        let view = ClinicalOps.toPendingRoundingPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingRoundingPlanViews([item, item]).count == 2)
    }
}
