@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureClaim("code-394", name: "name-446")
        let view = Consent.toDisclosureClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureClaimViews([item, item]).count == 2)
    }
}
