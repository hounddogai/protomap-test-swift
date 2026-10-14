@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveAssessmentAllocation("code-696", name: "name-238")
        let view = CareManagement.toAdaptiveAssessmentAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveAssessmentAllocationViews([item, item]).count == 2)
    }
}
