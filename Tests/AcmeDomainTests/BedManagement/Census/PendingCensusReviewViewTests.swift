@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingCensusReview("code-953", title: "title-646")
        let view = BedManagement.toPendingCensusReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingCensusReviewViews([item, item]).count == 2)
    }
}
