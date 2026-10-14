@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalCleaningLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalCleaningLedger("code-523", name: "name-736")
        let view = BedManagement.toRegionalCleaningLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalCleaningLedgerViews([item, item]).count == 2)
    }
}
