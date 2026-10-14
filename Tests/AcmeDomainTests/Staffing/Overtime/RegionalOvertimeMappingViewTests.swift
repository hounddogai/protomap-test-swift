@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalOvertimeMapping("code-519", name: "name-289")
        let view = Staffing.toRegionalOvertimeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalOvertimeMappingViews([item, item]).count == 2)
    }
}
