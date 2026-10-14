@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultRoundingDraft("code-253", label: "label-461")
        let view = ClinicalOps.toDefaultRoundingDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultRoundingDraftViews([item, item]).count == 2)
    }
}
