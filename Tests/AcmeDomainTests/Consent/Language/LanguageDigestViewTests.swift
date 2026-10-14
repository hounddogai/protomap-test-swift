@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageDigest("code-389", name: "name-861")
        let view = Consent.toLanguageDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageDigestViews([item, item]).count == 2)
    }
}
