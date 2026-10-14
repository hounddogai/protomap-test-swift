@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalAlertSummary("code-930", name: "name-550")
        let view = ClinicalOps.toGlobalAlertSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalAlertSummaryViews([item, item]).count == 2)
    }
}
