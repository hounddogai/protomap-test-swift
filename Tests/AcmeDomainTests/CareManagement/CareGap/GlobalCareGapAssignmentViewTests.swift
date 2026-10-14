@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalCareGapAssignment("code-314", name: "name-842")
        let view = CareManagement.toGlobalCareGapAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalCareGapAssignmentViews([item, item]).count == 2)
    }
}
