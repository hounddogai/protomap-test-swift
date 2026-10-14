@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusReview("code-305", name: "name-707")
        let view = BedManagement.toCensusReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusReviewViews([item, item]).count == 2)
    }
}
