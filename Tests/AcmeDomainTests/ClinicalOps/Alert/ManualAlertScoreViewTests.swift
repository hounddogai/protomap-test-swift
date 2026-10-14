@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newManualAlertScore("code-327", label: "label-874")
        let view = ClinicalOps.toManualAlertScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toManualAlertScoreViews([item, item]).count == 2)
    }
}
