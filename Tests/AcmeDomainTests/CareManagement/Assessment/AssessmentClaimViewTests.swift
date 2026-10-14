@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentClaim("code-800", label: "label-717")
        let view = CareManagement.toAssessmentClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentClaimViews([item, item]).count == 2)
    }
}
