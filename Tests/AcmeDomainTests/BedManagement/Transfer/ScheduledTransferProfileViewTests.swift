@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledTransferProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledTransferProfile("code-974", label: "label-108")
        let view = BedManagement.toScheduledTransferProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledTransferProfileViews([item, item]).count == 2)
    }
}
