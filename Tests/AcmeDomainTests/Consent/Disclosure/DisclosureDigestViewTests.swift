@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureDigest("code-402", label: "label-400")
        let view = Consent.toDisclosureDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureDigestViews([item, item]).count == 2)
    }
}
