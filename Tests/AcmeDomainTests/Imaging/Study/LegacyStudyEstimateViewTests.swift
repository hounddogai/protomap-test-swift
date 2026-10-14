@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLegacyStudyEstimate("code-628", title: "title-983")
        let view = Imaging.toLegacyStudyEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLegacyStudyEstimateViews([item, item]).count == 2)
    }
}
