@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolProfile("code-894", title: "title-899")
        let view = Imaging.toCareProtocolProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolProfileViews([item, item]).count == 2)
    }
}
