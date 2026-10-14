@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLegacyDisclosureClaim("code-155", label: "label-565")
        let view = Consent.toLegacyDisclosureClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLegacyDisclosureClaimViews([item, item]).count == 2)
    }
}
