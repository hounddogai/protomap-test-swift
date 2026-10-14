@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingCensusAllocation("code-575", title: "title-421")
        let view = BedManagement.toPendingCensusAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingCensusAllocationViews([item, item]).count == 2)
    }
}
