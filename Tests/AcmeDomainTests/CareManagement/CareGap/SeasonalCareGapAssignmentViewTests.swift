@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newSeasonalCareGapAssignment("code-86", name: "name-463")
        let view = CareManagement.toSeasonalCareGapAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toSeasonalCareGapAssignmentViews([item, item]).count == 2)
    }
}
