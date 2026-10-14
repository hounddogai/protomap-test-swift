@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        let view = Imaging.toCareProtocolPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolPreferenceViews([item, item]).count == 2)
    }
}
