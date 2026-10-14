@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        let view = Imaging.toPrimaryStudyReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryStudyReviewViews([item, item]).count == 2)
    }
}
