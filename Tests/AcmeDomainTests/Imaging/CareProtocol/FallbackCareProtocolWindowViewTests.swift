@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        let view = Imaging.toFallbackCareProtocolWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackCareProtocolWindowViews([item, item]).count == 2)
    }
}
