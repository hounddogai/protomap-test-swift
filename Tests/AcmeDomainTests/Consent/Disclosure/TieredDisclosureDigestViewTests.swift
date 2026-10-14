@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredDisclosureDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredDisclosureDigest("code-941", title: "title-969")
        let view = Consent.toTieredDisclosureDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredDisclosureDigestViews([item, item]).count == 2)
    }
}
