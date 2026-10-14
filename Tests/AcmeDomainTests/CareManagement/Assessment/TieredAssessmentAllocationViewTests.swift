@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredAssessmentAllocation("code-131", label: "label-865")
        let view = CareManagement.toTieredAssessmentAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredAssessmentAllocationViews([item, item]).count == 2)
    }
}
