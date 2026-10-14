@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryFloatPoolAssignment("code-859", label: "label-367")
        let view = Staffing.toPrimaryFloatPoolAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryFloatPoolAssignmentViews([item, item]).count == 2)
    }
}
