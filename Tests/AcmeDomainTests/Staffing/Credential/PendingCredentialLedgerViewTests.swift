@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingCredentialLedger("code-819", name: "name-226")
        let view = Staffing.toPendingCredentialLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingCredentialLedgerViews([item, item]).count == 2)
    }
}
