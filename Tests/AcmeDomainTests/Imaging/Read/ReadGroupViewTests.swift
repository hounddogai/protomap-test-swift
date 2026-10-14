@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadGroup("code-71", name: "name-932")
        let view = Imaging.toReadGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadGroupViews([item, item]).count == 2)
    }
}
