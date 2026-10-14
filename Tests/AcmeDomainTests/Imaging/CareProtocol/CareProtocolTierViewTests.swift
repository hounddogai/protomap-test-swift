@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolTier("code-400", title: "title-589")
        let view = Imaging.toCareProtocolTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolTierViews([item, item]).count == 2)
    }
}
