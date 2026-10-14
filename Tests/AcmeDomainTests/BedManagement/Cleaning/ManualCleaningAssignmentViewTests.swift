@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualCleaningAssignment("code-153", title: "title-95")
        let view = BedManagement.toManualCleaningAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualCleaningAssignmentViews([item, item]).count == 2)
    }
}
