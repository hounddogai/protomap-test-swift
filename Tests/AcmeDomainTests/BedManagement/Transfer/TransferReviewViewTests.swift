@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferReview("code-6", name: "name-192")
        let view = BedManagement.toTransferReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferReviewViews([item, item]).count == 2)
    }
}
