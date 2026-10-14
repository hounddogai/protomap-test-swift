@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        let view = ClinicalOps.toFallbackRoundingSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackRoundingSlotViews([item, item]).count == 2)
    }
}
