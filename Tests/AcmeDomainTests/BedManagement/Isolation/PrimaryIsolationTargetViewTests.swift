@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryIsolationTarget("code-202", name: "name-332")
        let view = BedManagement.toPrimaryIsolationTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryIsolationTargetViews([item, item]).count == 2)
    }
}
