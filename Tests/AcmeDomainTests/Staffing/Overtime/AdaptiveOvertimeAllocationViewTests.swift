@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveOvertimeAllocation("code-18", name: "name-427")
        let view = Staffing.toAdaptiveOvertimeAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveOvertimeAllocationViews([item, item]).count == 2)
    }
}
