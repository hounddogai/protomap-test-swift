@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newBatchedOvertimeAllocation("code-726", title: "title-414")
        let view = Staffing.toBatchedOvertimeAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toBatchedOvertimeAllocationViews([item, item]).count == 2)
    }
}
