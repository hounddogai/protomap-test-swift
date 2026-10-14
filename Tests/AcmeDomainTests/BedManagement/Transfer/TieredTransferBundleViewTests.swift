@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredTransferBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredTransferBundle("code-746", label: "label-31")
        let view = BedManagement.toTieredTransferBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredTransferBundleViews([item, item]).count == 2)
    }
}
