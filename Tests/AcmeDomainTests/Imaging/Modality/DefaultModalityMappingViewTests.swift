@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultModalityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        let view = Imaging.toDefaultModalityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toDefaultModalityMappingViews([item, item]).count == 2)
    }
}
