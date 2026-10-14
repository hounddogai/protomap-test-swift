@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormDraft("code-111", name: "name-680")
        let view = Consent.toConsentFormDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormDraftViews([item, item]).count == 2)
    }
}
