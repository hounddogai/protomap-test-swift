@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        let view = Consent.toRollingConsentFormWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingConsentFormWindowViews([item, item]).count == 2)
    }
}
