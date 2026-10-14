@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadRollup("code-15", title: "title-196")
        let view = Imaging.toReadRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadRollupViews([item, item]).count == 2)
    }
}
