@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingCareProtocolWindow("code-394", title: "title-636")
        let view = Imaging.toRollingCareProtocolWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingCareProtocolWindowViews([item, item]).count == 2)
    }
}
