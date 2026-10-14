@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalAssessmentRule("code-528", name: "name-183")
        let view = CareManagement.toGlobalAssessmentRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalAssessmentRuleViews([item, item]).count == 2)
    }
}
