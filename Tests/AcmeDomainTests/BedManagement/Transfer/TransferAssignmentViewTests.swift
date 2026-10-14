@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferAssignment("code-192", label: "label-60")
        let view = BedManagement.toTransferAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferAssignmentViews([item, item]).count == 2)
    }
}
