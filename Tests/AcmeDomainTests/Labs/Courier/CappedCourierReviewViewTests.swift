@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedCourierReview("code-504", title: "title-870")
        let view = Labs.toCappedCourierReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedCourierReviewViews([item, item]).count == 2)
    }
}
