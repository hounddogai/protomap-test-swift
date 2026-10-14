@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolEstimate("code-737", label: "label-178")
        let view = Imaging.toCareProtocolEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolEstimateViews([item, item]).count == 2)
    }
}
