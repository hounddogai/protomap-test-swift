@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessForecast("code-505", label: "label-2")
        let view = Consent.toWitnessForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessForecastViews([item, item]).count == 2)
    }
}
