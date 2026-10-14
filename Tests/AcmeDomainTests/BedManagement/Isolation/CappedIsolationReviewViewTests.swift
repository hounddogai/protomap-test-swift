@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedIsolationReview("code-764", name: "name-966")
        let view = BedManagement.toCappedIsolationReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedIsolationReviewViews([item, item]).count == 2)
    }
}
