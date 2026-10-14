@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertCycle("code-521", label: "label-845")
        let view = ClinicalOps.toAlertCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertCycleViews([item, item]).count == 2)
    }
}
