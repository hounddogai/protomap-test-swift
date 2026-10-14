@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusSlot("code-782", label: "label-351")
        let view = BedManagement.toCensusSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusSlotViews([item, item]).count == 2)
    }
}
