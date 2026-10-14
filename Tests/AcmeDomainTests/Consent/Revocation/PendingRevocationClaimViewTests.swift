@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingRevocationClaim("code-470", title: "title-261")
        let view = Consent.toPendingRevocationClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingRevocationClaimViews([item, item]).count == 2)
    }
}
