@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationAssignment("code-432", label: "label-893")
        let view = BedManagement.toIsolationAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationAssignmentViews([item, item]).count == 2)
    }
}
