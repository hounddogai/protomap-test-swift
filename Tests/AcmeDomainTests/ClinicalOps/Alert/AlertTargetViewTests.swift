@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertTarget("code-886", label: "label-242")
        let view = ClinicalOps.toAlertTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertTargetViews([item, item]).count == 2)
    }
}
