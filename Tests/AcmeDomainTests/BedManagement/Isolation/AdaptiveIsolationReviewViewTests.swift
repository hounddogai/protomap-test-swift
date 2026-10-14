@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveIsolationReview("code-264", title: "title-556")
        let view = BedManagement.toAdaptiveIsolationReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveIsolationReviewViews([item, item]).count == 2)
    }
}
