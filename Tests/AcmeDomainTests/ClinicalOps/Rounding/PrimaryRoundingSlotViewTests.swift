@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryRoundingSlot("code-419", name: "name-690")
        let view = ClinicalOps.toPrimaryRoundingSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryRoundingSlotViews([item, item]).count == 2)
    }
}
