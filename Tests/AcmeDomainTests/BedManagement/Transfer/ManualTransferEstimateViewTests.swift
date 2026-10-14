@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualTransferEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualTransferEstimate("code-737", name: "name-785")
        let view = BedManagement.toManualTransferEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualTransferEstimateViews([item, item]).count == 2)
    }
}
