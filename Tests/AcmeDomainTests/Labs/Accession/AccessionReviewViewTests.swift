@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        let view = Labs.toAccessionReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionReviewViews([item, item]).count == 2)
    }
}
