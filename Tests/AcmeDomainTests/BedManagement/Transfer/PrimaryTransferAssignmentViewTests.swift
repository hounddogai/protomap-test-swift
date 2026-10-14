@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        let view = BedManagement.toPrimaryTransferAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryTransferAssignmentViews([item, item]).count == 2)
    }
}
