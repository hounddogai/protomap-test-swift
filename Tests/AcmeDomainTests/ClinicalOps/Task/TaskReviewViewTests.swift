@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskReview("code-801", name: "name-295")
        let view = ClinicalOps.toTaskReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskReviewViews([item, item]).count == 2)
    }
}
