@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictReadSlot("code-82", title: "title-891")
        let view = Imaging.toStrictReadSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictReadSlotViews([item, item]).count == 2)
    }
}
