@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalRoundingTemplate("code-16", name: "name-717")
        let view = ClinicalOps.toGlobalRoundingTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalRoundingTemplateViews([item, item]).count == 2)
    }
}
