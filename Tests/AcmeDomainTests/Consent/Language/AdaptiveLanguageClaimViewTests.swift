@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveLanguageClaim("code-438", label: "label-591")
        let view = Consent.toAdaptiveLanguageClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveLanguageClaimViews([item, item]).count == 2)
    }
}
