@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualOutreachAssignment("code-298", label: "label-76")
        let view = CareManagement.toManualOutreachAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualOutreachAssignmentViews([item, item]).count == 2)
    }
}
