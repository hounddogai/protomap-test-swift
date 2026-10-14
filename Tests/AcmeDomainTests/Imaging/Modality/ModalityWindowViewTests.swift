@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityWindow("code-647", label: "label-499")
        let view = Imaging.toModalityWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityWindowViews([item, item]).count == 2)
    }
}
