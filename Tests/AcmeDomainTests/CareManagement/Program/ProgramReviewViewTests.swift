@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramReview("code-568", name: "name-897")
        let view = CareManagement.toProgramReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramReviewViews([item, item]).count == 2)
    }
}
