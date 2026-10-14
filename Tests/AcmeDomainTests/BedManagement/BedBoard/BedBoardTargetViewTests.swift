@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardTarget("code-478", label: "label-341")
        let view = BedManagement.toBedBoardTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardTargetViews([item, item]).count == 2)
    }
}
