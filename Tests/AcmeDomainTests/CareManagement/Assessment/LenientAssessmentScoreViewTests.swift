@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientAssessmentScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientAssessmentScore("code-549", name: "name-370")
        let view = CareManagement.toLenientAssessmentScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientAssessmentScoreViews([item, item]).count == 2)
    }
}
