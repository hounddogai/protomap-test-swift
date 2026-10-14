@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedBedBoardGroup("code-267", label: "label-170")
        let view = BedManagement.toCappedBedBoardGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedBedBoardGroupViews([item, item]).count == 2)
    }
}
