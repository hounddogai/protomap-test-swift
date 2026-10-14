@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredIsolationGroup("code-315", name: "name-804")
        let view = BedManagement.toTieredIsolationGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredIsolationGroupViews([item, item]).count == 2)
    }
}
