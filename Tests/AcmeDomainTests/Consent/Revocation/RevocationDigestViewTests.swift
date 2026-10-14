@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationDigest("code-408", title: "title-938")
        let view = Consent.toRevocationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationDigestViews([item, item]).count == 2)
    }
}
