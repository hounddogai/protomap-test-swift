@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        let view = Imaging.toLenientReadForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientReadForecastViews([item, item]).count == 2)
    }
}
