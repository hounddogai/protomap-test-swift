@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPrioritySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackPrioritySlot("code-691", title: "title-109")
        let view = Imaging.toFallbackPrioritySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackPrioritySlotViews([item, item]).count == 2)
    }
}
