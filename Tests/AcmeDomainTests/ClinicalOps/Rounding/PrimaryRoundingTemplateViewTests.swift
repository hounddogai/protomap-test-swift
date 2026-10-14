@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryRoundingTemplate("code-926", title: "title-997")
        let view = ClinicalOps.toPrimaryRoundingTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryRoundingTemplateViews([item, item]).count == 2)
    }
}
