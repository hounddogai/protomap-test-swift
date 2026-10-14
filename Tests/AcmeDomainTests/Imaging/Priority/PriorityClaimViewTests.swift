@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityClaim("code-592", title: "title-151")
        let view = Imaging.toPriorityClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityClaimViews([item, item]).count == 2)
    }
}
