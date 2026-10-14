@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryCareProtocolReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryCareProtocolReview("code-756", title: "title-817")
        let view = ClinicalOps.toPrimaryCareProtocolReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryCareProtocolReviewViews([item, item]).count == 2)
    }
}
