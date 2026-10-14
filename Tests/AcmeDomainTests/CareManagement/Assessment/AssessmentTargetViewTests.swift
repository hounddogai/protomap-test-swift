@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentTarget("code-468", label: "label-663")
        let view = CareManagement.toAssessmentTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentTargetViews([item, item]).count == 2)
    }
}
