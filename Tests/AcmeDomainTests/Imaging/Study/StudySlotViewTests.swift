@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudySlot("code-486", title: "title-49")
        let view = Imaging.toStudySlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudySlotViews([item, item]).count == 2)
    }
}
