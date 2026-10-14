@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityTier("code-729", label: "label-308")
        let view = Imaging.toPriorityTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityTierViews([item, item]).count == 2)
    }
}
