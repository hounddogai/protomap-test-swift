@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormTarget("code-380", name: "name-123")
        let view = Consent.toConsentFormTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormTargetViews([item, item]).count == 2)
    }
}
