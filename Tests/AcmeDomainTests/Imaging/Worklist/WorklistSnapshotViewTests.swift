@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistSnapshot("code-641", title: "title-645")
        let view = Imaging.toWorklistSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistSnapshotViews([item, item]).count == 2)
    }
}
