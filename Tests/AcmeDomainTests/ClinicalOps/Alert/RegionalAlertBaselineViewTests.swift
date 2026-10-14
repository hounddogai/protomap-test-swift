@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRegionalAlertBaseline("code-598", label: "label-257")
        let view = ClinicalOps.toRegionalAlertBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRegionalAlertBaselineViews([item, item]).count == 2)
    }
}
