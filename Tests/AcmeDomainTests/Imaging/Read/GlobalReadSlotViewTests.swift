@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        let view = Imaging.toGlobalReadSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalReadSlotViews([item, item]).count == 2)
    }
}
