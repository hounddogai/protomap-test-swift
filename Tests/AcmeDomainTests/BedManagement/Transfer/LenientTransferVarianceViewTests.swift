@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientTransferVariance("code-141", title: "title-315")
        let view = BedManagement.toLenientTransferVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientTransferVarianceViews([item, item]).count == 2)
    }
}
