@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackOvertimePolicy("code-825", name: "name-420")
        let view = Staffing.toFallbackOvertimePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackOvertimePolicyViews([item, item]).count == 2)
    }
}
