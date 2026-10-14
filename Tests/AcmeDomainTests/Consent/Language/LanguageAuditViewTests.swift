@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageAudit("code-733", name: "name-567")
        let view = Consent.toLanguageAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageAuditViews([item, item]).count == 2)
    }
}
