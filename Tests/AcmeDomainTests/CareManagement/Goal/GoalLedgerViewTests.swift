@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        let view = CareManagement.toGoalLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalLedgerViews([item, item]).count == 2)
    }
}
