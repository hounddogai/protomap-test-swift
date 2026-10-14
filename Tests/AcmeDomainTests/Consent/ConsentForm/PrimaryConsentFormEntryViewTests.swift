@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryConsentFormEntry("code-123", name: "name-94")
        let view = Consent.toPrimaryConsentFormEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryConsentFormEntryViews([item, item]).count == 2)
    }
}
