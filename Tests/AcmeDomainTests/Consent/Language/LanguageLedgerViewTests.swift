@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        let view = Consent.toLanguageLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageLedgerViews([item, item]).count == 2)
    }
}
