@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        let view = Imaging.toRegionalPriorityCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalPriorityCycleViews([item, item]).count == 2)
    }
}
