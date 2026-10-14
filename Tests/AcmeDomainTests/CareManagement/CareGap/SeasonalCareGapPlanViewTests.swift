@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalCareGapPlan("code-279", title: "title-477")
        let view = CareManagement.toSeasonalCareGapPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalCareGapPlanViews([item, item]).count == 2)
    }
}
