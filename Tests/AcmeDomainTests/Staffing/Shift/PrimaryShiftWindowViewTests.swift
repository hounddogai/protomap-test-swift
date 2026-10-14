@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryShiftWindow("code-107", label: "label-202")
        let view = Staffing.toPrimaryShiftWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryShiftWindowViews([item, item]).count == 2)
    }
}
