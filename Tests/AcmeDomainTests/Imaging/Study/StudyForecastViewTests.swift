@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyForecast("code-287", label: "label-791")
        let view = Imaging.toStudyForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyForecastViews([item, item]).count == 2)
    }
}
