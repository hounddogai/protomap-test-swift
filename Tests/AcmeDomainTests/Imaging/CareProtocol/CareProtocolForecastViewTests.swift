@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolForecast("code-388", name: "name-487")
        let view = Imaging.toCareProtocolForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolForecastViews([item, item]).count == 2)
    }
}
