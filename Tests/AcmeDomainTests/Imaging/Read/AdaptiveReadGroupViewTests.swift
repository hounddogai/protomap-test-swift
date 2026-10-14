@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        let view = Imaging.toAdaptiveReadGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveReadGroupViews([item, item]).count == 2)
    }
}
