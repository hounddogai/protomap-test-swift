@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledConsentFormClaim("code-443", title: "title-782")
        let view = Consent.toScheduledConsentFormClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledConsentFormClaimViews([item, item]).count == 2)
    }
}
