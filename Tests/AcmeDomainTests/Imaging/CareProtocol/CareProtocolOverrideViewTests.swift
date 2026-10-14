@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolOverride("code-769", label: "label-191")
        let view = Imaging.toCareProtocolOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolOverrideViews([item, item]).count == 2)
    }
}
