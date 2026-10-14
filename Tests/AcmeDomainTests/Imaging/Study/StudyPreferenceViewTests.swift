@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyPreference("code-145", name: "name-587")
        let view = Imaging.toStudyPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyPreferenceViews([item, item]).count == 2)
    }
}
