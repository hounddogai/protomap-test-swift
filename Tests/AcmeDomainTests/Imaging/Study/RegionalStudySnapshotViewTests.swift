@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalStudySnapshot("code-193", name: "name-938")
        let view = Imaging.toRegionalStudySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalStudySnapshotViews([item, item]).count == 2)
    }
}
