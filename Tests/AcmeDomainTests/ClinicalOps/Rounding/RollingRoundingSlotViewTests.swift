@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingRoundingSlot("code-964", label: "label-98")
        let view = ClinicalOps.toRollingRoundingSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingRoundingSlotViews([item, item]).count == 2)
    }
}
