@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryTaskTemplate("code-486", name: "name-114")
        let view = ClinicalOps.toPrimaryTaskTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryTaskTemplateViews([item, item]).count == 2)
    }
}
