@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierReview("code-625", name: "name-631")
        let view = Labs.toCourierReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierReviewViews([item, item]).count == 2)
    }
}
