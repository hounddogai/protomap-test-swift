@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        let view = BedManagement.toTransferGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferGroupViews([item, item]).count == 2)
    }
}
