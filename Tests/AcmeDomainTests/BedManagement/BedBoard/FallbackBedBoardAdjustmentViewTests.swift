@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackBedBoardAdjustment("code-490", label: "label-475")
        let view = BedManagement.toFallbackBedBoardAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackBedBoardAdjustmentViews([item, item]).count == 2)
    }
}
