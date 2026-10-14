@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        let view = Consent.toScheduledRevocationDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledRevocationDigestViews([item, item]).count == 2)
    }
}
