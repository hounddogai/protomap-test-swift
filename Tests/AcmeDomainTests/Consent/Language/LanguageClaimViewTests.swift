@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageClaim("code-422", label: "label-86")
        let view = Consent.toLanguageClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageClaimViews([item, item]).count == 2)
    }
}
