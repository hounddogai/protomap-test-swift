@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityCheckpoint("code-815", label: "label-98")
        let view = Imaging.toPriorityCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityCheckpointViews([item, item]).count == 2)
    }
}
