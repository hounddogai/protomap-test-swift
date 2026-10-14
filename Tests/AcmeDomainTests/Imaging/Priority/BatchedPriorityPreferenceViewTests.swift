@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        let view = Imaging.toBatchedPriorityPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toBatchedPriorityPreferenceViews([item, item]).count == 2)
    }
}
