@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualRoundingRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newManualRoundingRule("code-549", title: "title-624")
        let view = ClinicalOps.toManualRoundingRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toManualRoundingRuleViews([item, item]).count == 2)
    }
}
