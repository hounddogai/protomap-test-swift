@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadSnapshot("code-276", title: "title-992")
        let view = Imaging.toReadSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadSnapshotViews([item, item]).count == 2)
    }
}
