@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredOutreachPlan("code-424", label: "label-686")
        let view = CareManagement.toTieredOutreachPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredOutreachPlanViews([item, item]).count == 2)
    }
}
