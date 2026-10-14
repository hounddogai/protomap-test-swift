@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredReadOverride("code-908", label: "label-266")
        let view = Imaging.toTieredReadOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredReadOverrideViews([item, item]).count == 2)
    }
}
