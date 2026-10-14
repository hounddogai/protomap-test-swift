@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalPriorityTarget("code-111", label: "label-8")
        let view = Imaging.toRegionalPriorityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalPriorityTargetViews([item, item]).count == 2)
    }
}
