@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityBatch("code-729", title: "title-399")
        let view = Imaging.toModalityBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityBatchViews([item, item]).count == 2)
    }
}
