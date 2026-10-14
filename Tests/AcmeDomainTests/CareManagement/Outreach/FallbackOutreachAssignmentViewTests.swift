@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackOutreachAssignment("code-126", label: "label-253")
        let view = CareManagement.toFallbackOutreachAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackOutreachAssignmentViews([item, item]).count == 2)
    }
}
