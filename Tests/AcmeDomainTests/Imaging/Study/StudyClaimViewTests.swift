@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyClaim("code-433", label: "label-520")
        let view = Imaging.toStudyClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyClaimViews([item, item]).count == 2)
    }
}
