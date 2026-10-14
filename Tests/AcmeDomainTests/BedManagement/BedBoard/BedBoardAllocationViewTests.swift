@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardAllocation("code-645", label: "label-526")
        let view = BedManagement.toBedBoardAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardAllocationViews([item, item]).count == 2)
    }
}
