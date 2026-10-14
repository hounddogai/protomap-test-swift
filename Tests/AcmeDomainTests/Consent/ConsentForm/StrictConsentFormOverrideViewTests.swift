@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictConsentFormOverride("code-600", name: "name-967")
        let view = Consent.toStrictConsentFormOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictConsentFormOverrideViews([item, item]).count == 2)
    }
}
