@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLegacyCareProtocolPreference("code-589", title: "title-395")
        let view = Imaging.toLegacyCareProtocolPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLegacyCareProtocolPreferenceViews([item, item]).count == 2)
    }
}
