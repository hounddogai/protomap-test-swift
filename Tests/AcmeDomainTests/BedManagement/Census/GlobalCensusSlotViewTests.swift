@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCensusSlot("code-767", title: "title-763")
        let view = BedManagement.toGlobalCensusSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCensusSlotViews([item, item]).count == 2)
    }
}
