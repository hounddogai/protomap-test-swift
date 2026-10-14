@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistReview("code-384", label: "label-216")
        let view = Imaging.toWorklistReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistReviewViews([item, item]).count == 2)
    }
}
