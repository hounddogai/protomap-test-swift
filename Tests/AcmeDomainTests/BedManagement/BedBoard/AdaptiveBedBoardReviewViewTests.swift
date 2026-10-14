@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveBedBoardReview("code-328", name: "name-628")
        let view = BedManagement.toAdaptiveBedBoardReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveBedBoardReviewViews([item, item]).count == 2)
    }
}
