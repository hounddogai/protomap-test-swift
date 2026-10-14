@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultOutreachPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultOutreachPlan("code-176", title: "title-680")
        let view = CareManagement.toDefaultOutreachPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultOutreachPlanViews([item, item]).count == 2)
    }
}
