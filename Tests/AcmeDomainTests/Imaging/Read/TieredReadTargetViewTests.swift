@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredReadTarget("code-14", title: "title-565")
        let view = Imaging.toTieredReadTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredReadTargetViews([item, item]).count == 2)
    }
}
