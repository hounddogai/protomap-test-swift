@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientOutreachRule("code-686", name: "name-488")
        let view = CareManagement.toLenientOutreachRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientOutreachRuleViews([item, item]).count == 2)
    }
}
