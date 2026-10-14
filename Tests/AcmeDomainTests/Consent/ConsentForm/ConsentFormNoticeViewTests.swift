@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormNotice("code-914", name: "name-749")
        let view = Consent.toConsentFormNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormNoticeViews([item, item]).count == 2)
    }
}
