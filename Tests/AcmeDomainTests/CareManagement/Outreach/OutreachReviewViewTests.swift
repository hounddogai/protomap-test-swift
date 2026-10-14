@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachReview("code-677", title: "title-500")
        let view = CareManagement.toOutreachReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachReviewViews([item, item]).count == 2)
    }
}
