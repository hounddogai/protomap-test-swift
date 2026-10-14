@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolAllocation("code-641", title: "title-367")
        let view = Staffing.toFloatPoolAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolAllocationViews([item, item]).count == 2)
    }
}
