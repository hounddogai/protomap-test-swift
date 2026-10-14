@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationReview("code-91", title: "title-972")
        let view = BedManagement.toIsolationReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationReviewViews([item, item]).count == 2)
    }
}
