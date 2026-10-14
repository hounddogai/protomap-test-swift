@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryOrderSetDraft("code-48", label: "label-969")
        let view = ClinicalOps.toPrimaryOrderSetDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryOrderSetDraftViews([item, item]).count == 2)
    }
}
