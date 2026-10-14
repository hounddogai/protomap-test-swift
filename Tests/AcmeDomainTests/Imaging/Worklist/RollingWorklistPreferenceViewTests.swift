@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingWorklistPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingWorklistPreference("code-748", name: "name-148")
        let view = Imaging.toRollingWorklistPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingWorklistPreferenceViews([item, item]).count == 2)
    }
}
