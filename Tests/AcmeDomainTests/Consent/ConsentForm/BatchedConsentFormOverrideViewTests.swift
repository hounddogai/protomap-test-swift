@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedConsentFormOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newBatchedConsentFormOverride("code-957", title: "title-627")
        let view = Consent.toBatchedConsentFormOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toBatchedConsentFormOverrideViews([item, item]).count == 2)
    }
}
