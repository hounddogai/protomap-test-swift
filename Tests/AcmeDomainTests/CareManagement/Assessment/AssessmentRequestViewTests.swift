@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentRequest("code-595", title: "title-42")
        let view = CareManagement.toAssessmentRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentRequestViews([item, item]).count == 2)
    }
}
