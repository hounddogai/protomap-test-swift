@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyMetric("code-324", label: "label-952")
        let view = Imaging.toStudyMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyMetricViews([item, item]).count == 2)
    }
}
