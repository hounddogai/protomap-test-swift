@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newOrderSetSlot("code-687", title: "title-869")
        let view = ClinicalOps.toOrderSetSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toOrderSetSlotViews([item, item]).count == 2)
    }
}
