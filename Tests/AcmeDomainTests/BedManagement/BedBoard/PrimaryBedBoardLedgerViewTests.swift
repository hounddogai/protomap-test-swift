@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryBedBoardLedger("code-432", label: "label-715")
        let view = BedManagement.toPrimaryBedBoardLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryBedBoardLedgerViews([item, item]).count == 2)
    }
}
