@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalPriorityMapping("code-344", name: "name-605")
        let view = Imaging.toSeasonalPriorityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalPriorityMappingViews([item, item]).count == 2)
    }
}
