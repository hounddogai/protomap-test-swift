@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentThreshold("code-320", label: "label-899")
        let view = CareManagement.toAssessmentThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentThresholdViews([item, item]).count == 2)
    }
}
