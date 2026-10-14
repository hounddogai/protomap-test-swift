@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictLanguageDigest("code-211", title: "title-888")
        let view = Consent.toStrictLanguageDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictLanguageDigestViews([item, item]).count == 2)
    }
}
