@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolThreshold("code-580", name: "name-471")
        let view = Imaging.toCareProtocolThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolThresholdViews([item, item]).count == 2)
    }
}
