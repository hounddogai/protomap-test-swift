@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyThreshold("code-610", name: "name-193")
        let view = Imaging.toStudyThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyThresholdViews([item, item]).count == 2)
    }
}
