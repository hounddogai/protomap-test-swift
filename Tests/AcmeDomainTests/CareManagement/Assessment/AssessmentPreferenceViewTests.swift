@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentPreference("code-345", title: "title-318")
        let view = CareManagement.toAssessmentPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentPreferenceViews([item, item]).count == 2)
    }
}
