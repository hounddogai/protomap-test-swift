@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalStudyMetric("code-411", label: "label-585")
        let view = Imaging.toSeasonalStudyMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalStudyMetricViews([item, item]).count == 2)
    }
}
