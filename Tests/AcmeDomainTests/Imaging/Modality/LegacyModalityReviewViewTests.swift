@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLegacyModalityReview("code-133", label: "label-58")
        let view = Imaging.toLegacyModalityReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLegacyModalityReviewViews([item, item]).count == 2)
    }
}
