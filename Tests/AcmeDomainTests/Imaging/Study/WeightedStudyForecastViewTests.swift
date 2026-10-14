@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedStudyForecast("code-706", name: "name-281")
        let view = Imaging.toWeightedStudyForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedStudyForecastViews([item, item]).count == 2)
    }
}
