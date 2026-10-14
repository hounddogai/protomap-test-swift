@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackTransferRequest("code-141", title: "title-702")
        let view = BedManagement.toFallbackTransferRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackTransferRequestViews([item, item]).count == 2)
    }
}
