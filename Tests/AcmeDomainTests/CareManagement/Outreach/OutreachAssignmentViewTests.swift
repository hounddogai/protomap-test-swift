@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachAssignment("code-494", label: "label-436")
        let view = CareManagement.toOutreachAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachAssignmentViews([item, item]).count == 2)
    }
}
