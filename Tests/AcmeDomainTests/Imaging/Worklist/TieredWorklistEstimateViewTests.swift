@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredWorklistEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        let view = Imaging.toTieredWorklistEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredWorklistEstimateViews([item, item]).count == 2)
    }
}
