@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        let view = Imaging.toPrioritySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrioritySlotViews([item, item]).count == 2)
    }
}
