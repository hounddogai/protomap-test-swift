@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptivePriorityClaim("code-421", label: "label-252")
        let view = Imaging.toAdaptivePriorityClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptivePriorityClaimViews([item, item]).count == 2)
    }
}
