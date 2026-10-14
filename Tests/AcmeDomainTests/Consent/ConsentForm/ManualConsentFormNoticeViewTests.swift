@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualConsentFormNotice("code-53", label: "label-481")
        let view = Consent.toManualConsentFormNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualConsentFormNoticeViews([item, item]).count == 2)
    }
}
