@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalitySlot("code-583", label: "label-518")
        let view = Imaging.toModalitySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalitySlotViews([item, item]).count == 2)
    }
}
