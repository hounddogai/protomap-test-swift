@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackWorklistRequest("code-978", label: "label-296")
        let view = Imaging.toFallbackWorklistRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackWorklistRequestViews([item, item]).count == 2)
    }
}
