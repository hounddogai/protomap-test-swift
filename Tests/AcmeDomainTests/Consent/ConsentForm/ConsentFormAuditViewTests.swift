@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormAudit("code-12", name: "name-585")
        let view = Consent.toConsentFormAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormAuditViews([item, item]).count == 2)
    }
}
