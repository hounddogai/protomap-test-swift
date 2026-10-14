@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        let view = Imaging.toStrictCareProtocolMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictCareProtocolMappingViews([item, item]).count == 2)
    }
}
