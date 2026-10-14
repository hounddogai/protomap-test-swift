@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalGoalAssignment("code-829", label: "label-70")
        let view = CareManagement.toGlobalGoalAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalGoalAssignmentViews([item, item]).count == 2)
    }
}
