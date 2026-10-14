@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        let view = Imaging.toReadOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadOverrideViews([item, item]).count == 2)
    }
}
