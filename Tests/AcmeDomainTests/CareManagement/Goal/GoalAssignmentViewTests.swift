@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalAssignment("code-455", title: "title-100")
        let view = CareManagement.toGoalAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalAssignmentViews([item, item]).count == 2)
    }
}
