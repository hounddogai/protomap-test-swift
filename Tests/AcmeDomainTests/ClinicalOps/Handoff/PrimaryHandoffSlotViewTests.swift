@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryHandoffSlot("code-965", name: "name-713")
        let view = ClinicalOps.toPrimaryHandoffSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryHandoffSlotViews([item, item]).count == 2)
    }
}
