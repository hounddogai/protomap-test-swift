@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferLedger("code-364", label: "label-631")
        let view = BedManagement.toTransferLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferLedgerViews([item, item]).count == 2)
    }
}
