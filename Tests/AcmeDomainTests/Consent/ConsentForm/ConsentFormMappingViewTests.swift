@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormMapping("code-972", label: "label-60")
        let view = Consent.toConsentFormMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormMappingViews([item, item]).count == 2)
    }
}
