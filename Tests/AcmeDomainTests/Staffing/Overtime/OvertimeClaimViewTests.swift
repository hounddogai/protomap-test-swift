@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeClaim("code-607", label: "label-69")
        let view = Staffing.toOvertimeClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeClaimViews([item, item]).count == 2)
    }
}
