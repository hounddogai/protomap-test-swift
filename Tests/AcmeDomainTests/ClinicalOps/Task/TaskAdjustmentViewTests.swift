@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskAdjustment("code-521", label: "label-98")
        let view = ClinicalOps.toTaskAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskAdjustmentViews([item, item]).count == 2)
    }
}
