@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCensusReview("code-297", label: "label-430")
        let view = BedManagement.toLenientCensusReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCensusReviewViews([item, item]).count == 2)
    }
}
