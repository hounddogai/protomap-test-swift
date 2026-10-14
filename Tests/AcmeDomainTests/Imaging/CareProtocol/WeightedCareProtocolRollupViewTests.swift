@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedCareProtocolRollup("code-735", label: "label-753")
        let view = Imaging.toWeightedCareProtocolRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedCareProtocolRollupViews([item, item]).count == 2)
    }
}
