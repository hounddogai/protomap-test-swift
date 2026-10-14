@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledCleaningAssignment("code-271", name: "name-319")
        let view = BedManagement.toScheduledCleaningAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledCleaningAssignmentViews([item, item]).count == 2)
    }
}
