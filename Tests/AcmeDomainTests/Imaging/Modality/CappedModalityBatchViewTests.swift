@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCappedModalityBatch("code-673", name: "name-866")
        let view = Imaging.toCappedModalityBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCappedModalityBatchViews([item, item]).count == 2)
    }
}
