@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        let view = Imaging.toManualCareProtocolSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualCareProtocolSlotViews([item, item]).count == 2)
    }
}
