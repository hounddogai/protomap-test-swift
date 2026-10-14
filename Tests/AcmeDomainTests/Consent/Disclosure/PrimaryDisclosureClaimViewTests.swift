@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryDisclosureClaim("code-270", title: "title-820")
        let view = Consent.toPrimaryDisclosureClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryDisclosureClaimViews([item, item]).count == 2)
    }
}
