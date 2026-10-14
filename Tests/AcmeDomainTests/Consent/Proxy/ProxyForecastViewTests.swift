@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyForecast("code-801", name: "name-980")
        let view = Consent.toProxyForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyForecastViews([item, item]).count == 2)
    }
}
