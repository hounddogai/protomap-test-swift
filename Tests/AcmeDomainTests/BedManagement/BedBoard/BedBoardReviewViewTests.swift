@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardReview("code-505", name: "name-521")
        let view = BedManagement.toBedBoardReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardReviewViews([item, item]).count == 2)
    }
}
