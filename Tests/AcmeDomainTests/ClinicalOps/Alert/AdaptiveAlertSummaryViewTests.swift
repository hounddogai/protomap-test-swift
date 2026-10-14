@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveAlertSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveAlertSummary("code-748", title: "title-72")
        let view = ClinicalOps.toAdaptiveAlertSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveAlertSummaryViews([item, item]).count == 2)
    }
}
