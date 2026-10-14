@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        let view = Imaging.toCareProtocolRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolRollupViews([item, item]).count == 2)
    }
}
