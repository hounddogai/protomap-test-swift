@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingAlertReview("code-568", name: "name-540")
        let view = ClinicalOps.toRollingAlertReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingAlertReviewViews([item, item]).count == 2)
    }
}
