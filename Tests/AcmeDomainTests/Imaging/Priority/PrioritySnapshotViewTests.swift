@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        let view = Imaging.toPrioritySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrioritySnapshotViews([item, item]).count == 2)
    }
}
