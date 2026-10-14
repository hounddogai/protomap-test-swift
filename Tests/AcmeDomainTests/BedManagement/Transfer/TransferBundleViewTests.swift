@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferBundle("code-913", name: "name-314")
        let view = BedManagement.toTransferBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferBundleViews([item, item]).count == 2)
    }
}
