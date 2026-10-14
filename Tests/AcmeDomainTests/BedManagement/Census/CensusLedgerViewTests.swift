@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusLedger("code-523", name: "name-22")
        let view = BedManagement.toCensusLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusLedgerViews([item, item]).count == 2)
    }
}
