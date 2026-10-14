@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackAccessionReview("code-590", label: "label-212")
        let view = Labs.toFallbackAccessionReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackAccessionReviewViews([item, item]).count == 2)
    }
}
