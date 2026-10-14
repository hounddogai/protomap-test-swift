@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalOvertimeWindow("code-386", name: "name-539")
        let view = Staffing.toRegionalOvertimeWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalOvertimeWindowViews([item, item]).count == 2)
    }
}
