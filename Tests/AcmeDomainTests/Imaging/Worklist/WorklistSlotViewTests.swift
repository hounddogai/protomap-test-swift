@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        let view = Imaging.toWorklistSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistSlotViews([item, item]).count == 2)
    }
}
