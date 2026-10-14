@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPendingAssessmentPreference("code-601", label: "label-706")
        let view = CareManagement.toPendingAssessmentPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPendingAssessmentPreferenceViews([item, item]).count == 2)
    }
}
