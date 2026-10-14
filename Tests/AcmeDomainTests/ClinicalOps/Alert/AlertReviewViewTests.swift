@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertReview("code-790", label: "label-799")
        let view = ClinicalOps.toAlertReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertReviewViews([item, item]).count == 2)
    }
}
