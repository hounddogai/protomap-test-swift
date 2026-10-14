@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryCredentialLedger("code-828", name: "name-719")
        let view = Staffing.toPrimaryCredentialLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryCredentialLedgerViews([item, item]).count == 2)
    }
}
