@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormDigest("code-534", name: "name-79")
        let view = Consent.toConsentFormDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormDigestViews([item, item]).count == 2)
    }
}
