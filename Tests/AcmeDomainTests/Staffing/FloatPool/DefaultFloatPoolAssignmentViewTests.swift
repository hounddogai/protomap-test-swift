@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newDefaultFloatPoolAssignment("code-200", name: "name-100")
        let view = Staffing.toDefaultFloatPoolAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toDefaultFloatPoolAssignmentViews([item, item]).count == 2)
    }
}
