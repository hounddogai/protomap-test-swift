@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityReview("code-761", title: "title-759")
        let view = Imaging.toModalityReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityReviewViews([item, item]).count == 2)
    }
}
