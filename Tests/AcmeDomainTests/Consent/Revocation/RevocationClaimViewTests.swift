@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        let view = Consent.toRevocationClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationClaimViews([item, item]).count == 2)
    }
}
