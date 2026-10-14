@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalStudyBatch("code-908", label: "label-636")
        let view = Imaging.toRegionalStudyBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalStudyBatchViews([item, item]).count == 2)
    }
}
