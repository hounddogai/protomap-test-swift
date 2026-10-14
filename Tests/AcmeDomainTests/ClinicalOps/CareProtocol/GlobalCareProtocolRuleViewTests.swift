@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalCareProtocolRule("code-270", title: "title-913")
        let view = ClinicalOps.toGlobalCareProtocolRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalCareProtocolRuleViews([item, item]).count == 2)
    }
}
