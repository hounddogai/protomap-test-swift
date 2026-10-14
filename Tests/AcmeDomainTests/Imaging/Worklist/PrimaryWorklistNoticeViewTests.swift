@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryWorklistNotice("code-765", label: "label-345")
        let view = Imaging.toPrimaryWorklistNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryWorklistNoticeViews([item, item]).count == 2)
    }
}
