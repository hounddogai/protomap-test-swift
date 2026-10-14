@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftPolicy("code-615", label: "label-680")
        let view = Staffing.toShiftPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftPolicyViews([item, item]).count == 2)
    }
}
