@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityTarget("code-638", label: "label-518")
        let view = Imaging.toPriorityTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityTargetViews([item, item]).count == 2)
    }
}
