@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeLedger("code-345", title: "title-15")
        let view = Staffing.toOvertimeLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeLedgerViews([item, item]).count == 2)
    }
}
