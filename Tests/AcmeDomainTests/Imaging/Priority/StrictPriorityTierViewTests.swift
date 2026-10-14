@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        let view = Imaging.toStrictPriorityTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictPriorityTierViews([item, item]).count == 2)
    }
}
