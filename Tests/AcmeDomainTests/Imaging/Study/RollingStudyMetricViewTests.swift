@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        let view = Imaging.toRollingStudyMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingStudyMetricViews([item, item]).count == 2)
    }
}
