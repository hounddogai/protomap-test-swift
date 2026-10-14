@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredCareGapAssignment("code-942", name: "name-942")
        let view = CareManagement.toTieredCareGapAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredCareGapAssignmentViews([item, item]).count == 2)
    }
}
