@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledBedBoardTarget("code-271", label: "label-970")
        let view = BedManagement.toScheduledBedBoardTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledBedBoardTargetViews([item, item]).count == 2)
    }
}
