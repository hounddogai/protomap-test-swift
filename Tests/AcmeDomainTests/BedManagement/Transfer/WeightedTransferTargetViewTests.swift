@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newWeightedTransferTarget("code-220", label: "label-789")
        let view = BedManagement.toWeightedTransferTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toWeightedTransferTargetViews([item, item]).count == 2)
    }
}
