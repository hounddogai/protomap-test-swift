@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultTransferReview("code-617", name: "name-483")
        let view = BedManagement.toDefaultTransferReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultTransferReviewViews([item, item]).count == 2)
    }
}
