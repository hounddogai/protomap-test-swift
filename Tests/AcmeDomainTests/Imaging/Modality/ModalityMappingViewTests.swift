@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityMapping("code-677", name: "name-92")
        let view = Imaging.toModalityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityMappingViews([item, item]).count == 2)
    }
}
