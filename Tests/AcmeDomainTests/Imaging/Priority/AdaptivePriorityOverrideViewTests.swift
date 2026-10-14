@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        let view = Imaging.toAdaptivePriorityOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptivePriorityOverrideViews([item, item]).count == 2)
    }
}
