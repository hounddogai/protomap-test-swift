@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyBedBoardReview("code-475", name: "name-15")
        let view = BedManagement.toLegacyBedBoardReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyBedBoardReviewViews([item, item]).count == 2)
    }
}
