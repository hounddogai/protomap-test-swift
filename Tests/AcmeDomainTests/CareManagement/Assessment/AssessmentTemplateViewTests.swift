@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentTemplate("code-438", name: "name-169")
        let view = CareManagement.toAssessmentTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentTemplateViews([item, item]).count == 2)
    }
}
