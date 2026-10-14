@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormClaim("code-795", label: "label-111")
        let view = Consent.toConsentFormClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormClaimViews([item, item]).count == 2)
    }
}
