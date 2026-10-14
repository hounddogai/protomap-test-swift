@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualPriorityTarget("code-296", label: "label-372")
        let view = Imaging.toManualPriorityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualPriorityTargetViews([item, item]).count == 2)
    }
}
