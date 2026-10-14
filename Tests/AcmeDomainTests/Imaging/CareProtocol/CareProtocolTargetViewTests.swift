@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolTarget("code-420", title: "title-876")
        let view = Imaging.toCareProtocolTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolTargetViews([item, item]).count == 2)
    }
}
