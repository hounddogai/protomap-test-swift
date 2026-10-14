@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalCareProtocolBaseline("code-924", name: "name-329")
        let view = Imaging.toSeasonalCareProtocolBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalCareProtocolBaselineViews([item, item]).count == 2)
    }
}
