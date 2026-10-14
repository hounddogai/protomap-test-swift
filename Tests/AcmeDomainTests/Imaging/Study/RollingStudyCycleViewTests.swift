@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingStudyCycle("code-649", title: "title-821")
        let view = Imaging.toRollingStudyCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingStudyCycleViews([item, item]).count == 2)
    }
}
