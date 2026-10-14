@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityNotice("code-992", title: "title-486")
        let view = Imaging.toPriorityNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityNoticeViews([item, item]).count == 2)
    }
}
