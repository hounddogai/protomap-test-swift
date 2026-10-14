@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalShiftProfile("code-100", name: "name-635")
        let view = Staffing.toGlobalShiftProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalShiftProfileViews([item, item]).count == 2)
    }
}
