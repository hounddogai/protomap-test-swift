@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudySnapshot("code-138", name: "name-395")
        let view = Imaging.toStudySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudySnapshotViews([item, item]).count == 2)
    }
}
