@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackBedBoardTarget("code-81", label: "label-354")
        let view = BedManagement.toFallbackBedBoardTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackBedBoardTargetViews([item, item]).count == 2)
    }
}
