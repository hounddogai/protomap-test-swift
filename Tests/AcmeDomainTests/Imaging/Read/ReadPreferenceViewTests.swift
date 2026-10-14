@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadPreference("code-373", label: "label-872")
        let view = Imaging.toReadPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadPreferenceViews([item, item]).count == 2)
    }
}
