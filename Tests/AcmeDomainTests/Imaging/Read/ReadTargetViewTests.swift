@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadTarget("code-56", label: "label-77")
        let view = Imaging.toReadTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadTargetViews([item, item]).count == 2)
    }
}
