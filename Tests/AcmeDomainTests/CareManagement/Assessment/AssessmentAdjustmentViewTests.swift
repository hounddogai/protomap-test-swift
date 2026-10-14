@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentAdjustment("code-631", label: "label-638")
        let view = CareManagement.toAssessmentAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentAdjustmentViews([item, item]).count == 2)
    }
}
