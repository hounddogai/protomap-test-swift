@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedModalityProfile("code-330", name: "name-692")
        let view = Imaging.toWeightedModalityProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedModalityProfileViews([item, item]).count == 2)
    }
}
