@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackModalityGroup("code-423", title: "title-279")
        let view = Imaging.toFallbackModalityGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackModalityGroupViews([item, item]).count == 2)
    }
}
