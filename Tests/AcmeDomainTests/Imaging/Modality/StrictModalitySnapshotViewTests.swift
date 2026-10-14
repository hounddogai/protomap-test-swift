@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalitySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        let view = Imaging.toStrictModalitySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictModalitySnapshotViews([item, item]).count == 2)
    }
}
