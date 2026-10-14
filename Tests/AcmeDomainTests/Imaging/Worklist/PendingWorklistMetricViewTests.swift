@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingWorklistMetric("code-367", label: "label-202")
        let view = Imaging.toPendingWorklistMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingWorklistMetricViews([item, item]).count == 2)
    }
}
