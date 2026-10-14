@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingCleaningSlot("code-417", title: "title-807")
        let view = BedManagement.toRollingCleaningSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingCleaningSlotViews([item, item]).count == 2)
    }
}
