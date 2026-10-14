@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualReadEstimate("code-132", title: "title-721")
        let view = Imaging.toManualReadEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualReadEstimateViews([item, item]).count == 2)
    }
}
