@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferVariance("code-456", title: "title-922")
        let view = BedManagement.toTransferVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferVarianceViews([item, item]).count == 2)
    }
}
