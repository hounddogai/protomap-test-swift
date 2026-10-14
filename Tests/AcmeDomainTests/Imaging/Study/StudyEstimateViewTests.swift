@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyEstimate("code-354", name: "name-691")
        let view = Imaging.toStudyEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyEstimateViews([item, item]).count == 2)
    }
}
