@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        let view = Staffing.toCappedShiftExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedShiftExceptionViews([item, item]).count == 2)
    }
}
