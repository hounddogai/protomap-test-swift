@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualModalityMapping("code-580", title: "title-882")
        let view = Imaging.toManualModalityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualModalityMappingViews([item, item]).count == 2)
    }
}
