@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertSummary("code-425", label: "label-363")
        let view = ClinicalOps.toAlertSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertSummaryViews([item, item]).count == 2)
    }
}
