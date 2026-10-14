@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedCareGapAssignment("code-159", title: "title-593")
        let view = CareManagement.toBatchedCareGapAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedCareGapAssignmentViews([item, item]).count == 2)
    }
}
