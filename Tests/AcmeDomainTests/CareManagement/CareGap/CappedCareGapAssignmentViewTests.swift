@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedCareGapAssignment("code-217", label: "label-197")
        let view = CareManagement.toCappedCareGapAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedCareGapAssignmentViews([item, item]).count == 2)
    }
}
