@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        let view = Imaging.toReadWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadWindowViews([item, item]).count == 2)
    }
}
