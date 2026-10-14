@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryCredentialReview("code-701", label: "label-832")
        let view = Staffing.toPrimaryCredentialReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryCredentialReviewViews([item, item]).count == 2)
    }
}
