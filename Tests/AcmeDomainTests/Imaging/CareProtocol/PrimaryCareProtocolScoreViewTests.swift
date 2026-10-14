@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryCareProtocolScore("code-935", name: "name-346")
        let view = Imaging.toPrimaryCareProtocolScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryCareProtocolScoreViews([item, item]).count == 2)
    }
}
