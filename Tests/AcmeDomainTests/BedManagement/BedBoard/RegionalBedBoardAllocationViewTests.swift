@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalBedBoardAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalBedBoardAllocation("code-731", title: "title-508")
        let view = BedManagement.toRegionalBedBoardAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalBedBoardAllocationViews([item, item]).count == 2)
    }
}
