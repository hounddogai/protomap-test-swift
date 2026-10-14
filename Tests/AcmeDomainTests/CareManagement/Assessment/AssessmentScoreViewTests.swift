@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentScore("code-590", title: "title-597")
        let view = CareManagement.toAssessmentScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentScoreViews([item, item]).count == 2)
    }
}
