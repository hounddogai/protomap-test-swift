@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualConsentFormEntry("code-876", name: "name-93")
        let view = Consent.toManualConsentFormEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualConsentFormEntryViews([item, item]).count == 2)
    }
}
