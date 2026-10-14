@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudyBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredStudyBatch("code-623", name: "name-564")
        let view = Imaging.toTieredStudyBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredStudyBatchViews([item, item]).count == 2)
    }
}
