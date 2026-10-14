@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newSeasonalDisclosureLedger("code-926", label: "label-133")
        let view = Consent.toSeasonalDisclosureLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toSeasonalDisclosureLedgerViews([item, item]).count == 2)
    }
}
