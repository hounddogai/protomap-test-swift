@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        let view = BedManagement.toTieredIsolationMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredIsolationMilestoneViews([item, item]).count == 2)
    }
}
