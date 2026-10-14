@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadMapping("code-925", name: "name-276")
        let view = Imaging.toReadMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadMappingViews([item, item]).count == 2)
    }
}
