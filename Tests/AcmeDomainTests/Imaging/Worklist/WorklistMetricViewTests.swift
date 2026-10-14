@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        let view = Imaging.toWorklistMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistMetricViews([item, item]).count == 2)
    }
}
