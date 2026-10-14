@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDischargePlanAllocation("code-47", title: "title-883")
        let view = BedManagement.toDischargePlanAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDischargePlanAllocationViews([item, item]).count == 2)
    }
}
