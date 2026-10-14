@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedModalityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        let view = Imaging.toBatchedModalityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toBatchedModalityMappingViews([item, item]).count == 2)
    }
}
