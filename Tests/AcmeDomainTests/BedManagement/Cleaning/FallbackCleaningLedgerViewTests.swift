@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackCleaningLedger("code-499", label: "label-498")
        let view = BedManagement.toFallbackCleaningLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackCleaningLedgerViews([item, item]).count == 2)
    }
}
