@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledAssessmentThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledAssessmentThreshold("code-237", title: "title-697")
        let view = CareManagement.toScheduledAssessmentThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledAssessmentThresholdViews([item, item]).count == 2)
    }
}
