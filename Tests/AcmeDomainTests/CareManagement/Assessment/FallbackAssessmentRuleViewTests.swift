@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackAssessmentRule("code-192", name: "name-801")
        let view = CareManagement.toFallbackAssessmentRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackAssessmentRuleViews([item, item]).count == 2)
    }
}
