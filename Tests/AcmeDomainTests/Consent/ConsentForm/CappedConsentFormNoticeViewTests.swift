@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        let view = Consent.toCappedConsentFormNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedConsentFormNoticeViews([item, item]).count == 2)
    }
}
