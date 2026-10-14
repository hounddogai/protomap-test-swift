@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackOutreachRule("code-971", label: "label-270")
        let view = CareManagement.toFallbackOutreachRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackOutreachRuleViews([item, item]).count == 2)
    }
}
