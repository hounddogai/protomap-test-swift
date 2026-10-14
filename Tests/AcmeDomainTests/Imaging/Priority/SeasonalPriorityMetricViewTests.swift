@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalPriorityMetric("code-982", label: "label-472")
        let view = Imaging.toSeasonalPriorityMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalPriorityMetricViews([item, item]).count == 2)
    }
}
