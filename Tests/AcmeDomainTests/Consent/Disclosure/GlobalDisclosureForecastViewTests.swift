@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newGlobalDisclosureForecast("code-466", label: "label-800")
        let view = Consent.toGlobalDisclosureForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toGlobalDisclosureForecastViews([item, item]).count == 2)
    }
}
