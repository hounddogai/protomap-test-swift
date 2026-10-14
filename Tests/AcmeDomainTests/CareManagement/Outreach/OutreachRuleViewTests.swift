@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachRule("code-991", title: "title-284")
        let view = CareManagement.toOutreachRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachRuleViews([item, item]).count == 2)
    }
}
