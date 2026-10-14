@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryModalityReview("code-72", title: "title-285")
        let view = Imaging.toPrimaryModalityReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryModalityReviewViews([item, item]).count == 2)
    }
}
