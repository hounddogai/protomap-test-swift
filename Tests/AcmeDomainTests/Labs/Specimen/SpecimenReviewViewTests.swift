@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenReview("code-64", label: "label-23")
        let view = Labs.toSpecimenReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenReviewViews([item, item]).count == 2)
    }
}
