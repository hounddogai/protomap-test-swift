@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientBedBoardAllocation("code-47", label: "label-987")
        let view = BedManagement.toLenientBedBoardAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientBedBoardAllocationViews([item, item]).count == 2)
    }
}
