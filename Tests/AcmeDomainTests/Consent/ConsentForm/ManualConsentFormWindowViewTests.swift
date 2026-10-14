@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        let view = Consent.toManualConsentFormWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toManualConsentFormWindowViews([item, item]).count == 2)
    }
}
