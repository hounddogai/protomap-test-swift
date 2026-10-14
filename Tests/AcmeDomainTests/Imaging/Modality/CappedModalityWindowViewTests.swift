@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCappedModalityWindow("code-335", name: "name-293")
        let view = Imaging.toCappedModalityWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCappedModalityWindowViews([item, item]).count == 2)
    }
}
