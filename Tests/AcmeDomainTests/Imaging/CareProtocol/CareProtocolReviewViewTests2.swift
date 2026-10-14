@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolReview("code-976", label: "label-301")
        let view = Imaging.toCareProtocolReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolReviewViews([item, item]).count == 2)
    }
}
