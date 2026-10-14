@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingLanguageDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        let view = Consent.toPendingLanguageDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingLanguageDigestViews([item, item]).count == 2)
    }
}
