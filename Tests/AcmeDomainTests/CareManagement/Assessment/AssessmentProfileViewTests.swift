@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentProfile("code-184", name: "name-734")
        let view = CareManagement.toAssessmentProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentProfileViews([item, item]).count == 2)
    }
}
