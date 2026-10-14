@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledTaskReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledTaskReview("code-487", label: "label-921")
        let view = ClinicalOps.toScheduledTaskReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledTaskReviewViews([item, item]).count == 2)
    }
}
