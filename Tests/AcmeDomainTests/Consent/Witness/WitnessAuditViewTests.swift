@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessAudit("code-272", title: "title-483")
        let view = Consent.toWitnessAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessAuditViews([item, item]).count == 2)
    }
}
