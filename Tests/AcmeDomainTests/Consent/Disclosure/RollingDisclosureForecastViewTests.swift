@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingDisclosureForecast("code-895", title: "title-925")
        let view = Consent.toRollingDisclosureForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingDisclosureForecastViews([item, item]).count == 2)
    }
}
