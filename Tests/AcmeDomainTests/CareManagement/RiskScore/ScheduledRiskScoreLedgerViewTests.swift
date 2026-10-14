@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledRiskScoreLedger("code-57", title: "title-160")
        let view = CareManagement.toScheduledRiskScoreLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledRiskScoreLedgerViews([item, item]).count == 2)
    }
}
