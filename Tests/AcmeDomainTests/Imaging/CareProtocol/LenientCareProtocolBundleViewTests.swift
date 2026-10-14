@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientCareProtocolBundle("code-275", label: "label-726")
        let view = Imaging.toLenientCareProtocolBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientCareProtocolBundleViews([item, item]).count == 2)
    }
}
