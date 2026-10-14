@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferWindow("code-505", title: "title-429")
        let view = BedManagement.toTransferWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferWindowViews([item, item]).count == 2)
    }
}
