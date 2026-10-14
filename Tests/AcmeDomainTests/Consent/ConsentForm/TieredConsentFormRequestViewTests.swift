@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        let view = Consent.toTieredConsentFormRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredConsentFormRequestViews([item, item]).count == 2)
    }
}
