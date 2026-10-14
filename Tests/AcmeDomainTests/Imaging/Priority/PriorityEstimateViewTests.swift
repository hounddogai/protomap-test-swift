@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityEstimate("code-841", label: "label-53")
        let view = Imaging.toPriorityEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityEstimateViews([item, item]).count == 2)
    }
}
