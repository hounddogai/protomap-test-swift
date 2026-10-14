@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        let view = Imaging.toLenientStudyMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientStudyMetricViews([item, item]).count == 2)
    }
}
