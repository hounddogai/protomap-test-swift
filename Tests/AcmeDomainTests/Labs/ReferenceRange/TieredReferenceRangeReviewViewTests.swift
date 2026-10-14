@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredReferenceRangeReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newTieredReferenceRangeReview("code-174", label: "label-366")
        let view = Labs.toTieredReferenceRangeReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toTieredReferenceRangeReviewViews([item, item]).count == 2)
    }
}
