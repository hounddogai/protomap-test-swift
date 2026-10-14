@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        let view = Consent.toConsentFormRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormRequestViews([item, item]).count == 2)
    }
}
