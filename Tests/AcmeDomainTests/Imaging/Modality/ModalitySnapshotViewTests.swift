@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalitySnapshot("code-636", title: "title-239")
        let view = Imaging.toModalitySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalitySnapshotViews([item, item]).count == 2)
    }
}
