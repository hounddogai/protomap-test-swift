@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        let view = Imaging.toTieredStudySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredStudySnapshotViews([item, item]).count == 2)
    }
}
