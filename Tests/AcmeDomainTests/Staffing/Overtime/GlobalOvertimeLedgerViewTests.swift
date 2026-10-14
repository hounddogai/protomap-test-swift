@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalOvertimeLedger("code-989", name: "name-923")
        let view = Staffing.toGlobalOvertimeLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalOvertimeLedgerViews([item, item]).count == 2)
    }
}
