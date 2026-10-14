@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingCensusLedger("code-427", name: "name-697")
        let view = BedManagement.toRollingCensusLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingCensusLedgerViews([item, item]).count == 2)
    }
}
