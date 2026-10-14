@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistWindow("code-473", title: "title-104")
        let view = Imaging.toWorklistWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistWindowViews([item, item]).count == 2)
    }
}
