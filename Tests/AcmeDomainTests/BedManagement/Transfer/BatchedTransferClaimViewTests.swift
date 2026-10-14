@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedTransferClaim("code-244", name: "name-119")
        let view = BedManagement.toBatchedTransferClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedTransferClaimViews([item, item]).count == 2)
    }
}
