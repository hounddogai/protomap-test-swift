@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningSlot("code-558", label: "label-528")
        let view = BedManagement.toCleaningSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningSlotViews([item, item]).count == 2)
    }
}
