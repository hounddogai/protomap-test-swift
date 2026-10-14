@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedReadPreference("code-253", title: "title-753")
        let view = Imaging.toWeightedReadPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedReadPreferenceViews([item, item]).count == 2)
    }
}
