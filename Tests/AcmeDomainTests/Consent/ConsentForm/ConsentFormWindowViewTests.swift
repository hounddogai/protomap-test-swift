@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormWindow("code-978", label: "label-40")
        let view = Consent.toConsentFormWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormWindowViews([item, item]).count == 2)
    }
}
