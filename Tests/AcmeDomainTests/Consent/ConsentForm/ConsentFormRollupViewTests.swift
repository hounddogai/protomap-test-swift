@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormRollup("code-195", label: "label-694")
        let view = Consent.toConsentFormRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormRollupViews([item, item]).count == 2)
    }
}
