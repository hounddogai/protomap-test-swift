@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptivePriorityRollup("code-761", label: "label-817")
        let view = Imaging.toAdaptivePriorityRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptivePriorityRollupViews([item, item]).count == 2)
    }
}
