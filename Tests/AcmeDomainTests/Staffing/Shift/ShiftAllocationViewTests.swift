@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftAllocation("code-78", title: "title-496")
        let view = Staffing.toShiftAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftAllocationViews([item, item]).count == 2)
    }
}
