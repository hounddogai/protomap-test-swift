@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRoundingTemplate("code-408", name: "name-287")
        let view = ClinicalOps.toRoundingTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRoundingTemplateViews([item, item]).count == 2)
    }
}
