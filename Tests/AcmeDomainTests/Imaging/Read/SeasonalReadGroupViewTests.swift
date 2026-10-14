@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalReadGroup("code-147", label: "label-143")
        let view = Imaging.toSeasonalReadGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalReadGroupViews([item, item]).count == 2)
    }
}
