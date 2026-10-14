@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentAllocation("code-869", name: "name-467")
        let view = CareManagement.toAssessmentAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentAllocationViews([item, item]).count == 2)
    }
}
