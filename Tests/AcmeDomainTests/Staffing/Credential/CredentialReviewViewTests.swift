@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialReview("code-291", title: "title-474")
        let view = Staffing.toCredentialReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialReviewViews([item, item]).count == 2)
    }
}
