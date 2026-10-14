@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusAssignment("code-511", title: "title-422")
        let view = BedManagement.toCensusAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusAssignmentViews([item, item]).count == 2)
    }
}
