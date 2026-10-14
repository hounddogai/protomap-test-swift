@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientRoundingTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLenientRoundingTemplate("code-112", name: "name-263")
        let view = ClinicalOps.toLenientRoundingTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLenientRoundingTemplateViews([item, item]).count == 2)
    }
}
