@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityTarget("code-238", title: "title-475")
        let view = Imaging.toModalityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityTargetViews([item, item]).count == 2)
    }
}
