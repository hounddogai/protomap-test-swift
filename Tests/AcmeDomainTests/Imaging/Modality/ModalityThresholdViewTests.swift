@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityThreshold("code-766", title: "title-381")
        let view = Imaging.toModalityThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityThresholdViews([item, item]).count == 2)
    }
}
