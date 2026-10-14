@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistGroup("code-62", title: "title-615")
        let view = Imaging.toWorklistGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistGroupViews([item, item]).count == 2)
    }
}
