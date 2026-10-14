@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolBatch("code-678", name: "name-965")
        let view = Imaging.toCareProtocolBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolBatchViews([item, item]).count == 2)
    }
}
