@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingWorklistEstimate("code-758", name: "name-859")
        let view = Imaging.toPendingWorklistEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingWorklistEstimateViews([item, item]).count == 2)
    }
}
