@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyAlertSlot("code-39", label: "label-577")
        let view = ClinicalOps.toLegacyAlertSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyAlertSlotViews([item, item]).count == 2)
    }
}
