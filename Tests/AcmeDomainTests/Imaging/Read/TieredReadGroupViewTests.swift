@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredReadGroup("code-630", name: "name-517")
        let view = Imaging.toTieredReadGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredReadGroupViews([item, item]).count == 2)
    }
}
