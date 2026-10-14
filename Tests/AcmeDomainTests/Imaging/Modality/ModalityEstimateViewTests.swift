@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        let view = Imaging.toModalityEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityEstimateViews([item, item]).count == 2)
    }
}
