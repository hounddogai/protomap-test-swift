@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferThreshold("code-876", name: "name-956")
        let view = BedManagement.toTransferThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferThresholdViews([item, item]).count == 2)
    }
}
