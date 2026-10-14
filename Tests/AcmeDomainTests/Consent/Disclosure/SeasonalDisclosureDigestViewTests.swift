@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        let view = Consent.toSeasonalDisclosureDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalDisclosureDigestViews([item, item]).count == 2)
    }
}
