@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newTieredModalityProfile("code-934", name: "name-228")
        let view = Imaging.toTieredModalityProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toTieredModalityProfileViews([item, item]).count == 2)
    }
}
