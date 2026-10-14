@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        let view = Imaging.toManualCareProtocolBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualCareProtocolBundleViews([item, item]).count == 2)
    }
}
