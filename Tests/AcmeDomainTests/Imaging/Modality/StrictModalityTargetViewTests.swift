@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictModalityTarget("code-556", label: "label-991")
        let view = Imaging.toStrictModalityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictModalityTargetViews([item, item]).count == 2)
    }
}
