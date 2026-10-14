@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingAlertReview("code-480", label: "label-792")
        let view = ClinicalOps.toPendingAlertReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingAlertReviewViews([item, item]).count == 2)
    }
}
