@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertSlot("code-159", title: "title-917")
        let view = ClinicalOps.toAlertSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertSlotViews([item, item]).count == 2)
    }
}
