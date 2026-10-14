@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskSlot("code-24", name: "name-419")
        let view = ClinicalOps.toTaskSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskSlotViews([item, item]).count == 2)
    }
}
